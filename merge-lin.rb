
module PackShoes
 require 'fileutils'
 def PackShoes.rewrite a, before, hsh
    File.open(before) do |b|
      b.each do |line|
        a << line.gsub(/\#\{(\w+)\}/) {
          if hsh[$1] 
            hsh[$1]
          else
            '#{'+$1+'}'
          end
        }
      end
    end
  end
  
  def PackShoes.merge_linux opts
    # setup defaults if not in the opts
    opts['publisher'] = 'shoerb' unless opts['publisher']
    opts['website'] = 'http://shoesrb.com/' unless opts['website']
    opts['hkey_org'] = 'Hackety.org' unless opts['hkey_org']
    opts['linux_where'] = '/usr/local' unless opts['linux_where']
    toplevel = []
    Dir.chdir(DIR) do
      Dir.glob('*') {|f| toplevel << f}
    end
    exclude = %w(static CHANGELOG.txt cshoes.exe gmon.out README.txt
      samples package VERSION.txt)
    #exclude = []
    #packdir = 'packdir'
    packdir = "#{opts['app_name']}-app"
    rm_rf packdir
    mkdir_p(packdir) # where fpm will find it.
    # copy shoes
    (toplevel-exclude).each do |p|
      cp_r File.join(DIR, p), packdir
    end
    # do the license stuff
    licf = File.open("#{packdir}/COPYING.txt", 'w')
    if opts['license'] && File.exist?(opts['license'])
      IO.foreach(opts['license']) {|ln| licf.puts ln}
    end
    IO.foreach("#{DIR}/COPYING.txt") {|ln| licf.puts ln}  
    licf.close
    # we do need some statics for console to work. 
    mkdir_p "#{packdir}/static"
    Dir.glob("#{DIR}/static/icon*.png") {|p| cp p, "#{packdir}/static" }
    if opts['app_png']
      cp "#{opts['app_loc']}/#{opts['app_png']}", "#{packdir}/static/app-icon.png"
    end
    # remove chipmonk and ftsearch unless requested
    rbmm = RUBY_VERSION[/\d.\d/].to_str
    exts = opts['include_exts'] # returns []
    if  !exts || ! exts.include?('ftsearch')
      puts "removing ftsearchrt.so"
      rm "#{packdir}/lib/ruby/#{rbmm}.0/i386-mingw32/ftsearchrt.so" 
      rm_rf "#{packdir}/lib/shoes/help.rb"
      rm_rf "#{packdir}/lib/shoes/search.rb"
    end
    if  !exts || ! exts.include?('chipmunk')
      puts "removing chipmunk"
      rm "#{packdir}/lib/ruby/#{rbmm}.0/i386-mingw32/chipmunk.so"
      rm "#{packdir}/lib/shoes/chipmunk.rb"
    end
    # get rid of some things in lib
    rm_rf "#{packdir}/lib/exerb"
    rm_rf "#{packdir}/lib/gtk-2.0" if File.exist? "#{packdir}/lib/gtk-2.0"
    # remove unreachable code in packdir/lib/shoes/ like help, app-package ...
    ['cobbler', 'debugger', 'irb', 'pack', 'app_package', 'packshoes',
      'remote_debugger', 'winject', 'envgem'].each {|f| rm "#{packdir}/lib/shoes/#{f}.rb" }
  
    # copy app contents (file/dir at a time)
    app_contents = Dir.glob("#{opts['app_loc']}/*")
    app_contents.each do |p|
     cp_r p, packdir
    end
    #create new lib/shoes.rb with rewrite
    newf = File.open("#{packdir}/lib/shoes.rb", 'w')
    rewrite newf, 'min-shoes.rb', {'APP_START' => opts['app_start'] }
    newf.close
    # create a new lib/shoes/log.rb with rewrite
    logf = File.open("#{packdir}/lib/shoes/log.rb", 'w')
    rewrite logf, 'min-log.rb', {'CONSOLE_HDR' => "#{opts['app_name']} Errors"}
    logf.close
    # copy/remove gems - tricksy - pay attention
    # remove the Shoes built-in gems if not in the list 
    incl_gems = opts['include_gems']
    rm_gems = []
    Dir.glob("#{packdir}/lib/ruby/gems/#{rbmm}.0/specifications/*gemspec") do |p|
      gem = File.basename(p, '.gemspec')
      if incl_gems.include?(gem)
        puts "Keeping Shoes gem: #{gem}"
        incl_gems.delete(gem)
      else
        rm_gems << gem
      end
    end
    sgpath = "#{packdir}/lib/ruby/gems/#{rbmm}.0"
    # sqlite is a special case so delete it differently - trickery
    if !incl_gems.include?('sqlite3')
      spec = Dir.glob("#{sgpath}/specifications/default/sqlite3*.gemspec")
      rm spec[0]
      rm_gems << File.basename(spec[0],'.gemspec')
    else
      incl_gems.delete("sglite3")
    end
    rm_gems.each do |g|
      puts "Deleting #{g}"
      rm_rf "#{sgpath}/specifications/#{g}.gemspec"
      rm_rf "#{sgpath}/extensions/#{RUBY_PLATFORM}/#{rbmm}.0/#{g}"
      rm_rf "#{sgpath}/gems/#{g}"
    end

    # copy requested gems from user's Shoes GEMS_DIR
    incl_gems.delete('sqlite3') if incl_gems.include?('sqlite3')
    incl_gems.each do |name| 
      puts "Copy #{name}"
      cp "#{GEMS_DIR}/specifications/#{name}.gemspec", "#{sgpath}/specifications"
      # does the gem have binary?
      built = "#{GEMS_DIR}/extensions/#{RUBY_PLATFORM}/#{rbmm}.0/#{name}/gem.build_complete"
      if File.exist? built
        mkdir_p "#{sgpath}/extensions/#{RUBY_PLATFORM}/#{rbmm}.0/#{name}"
        cp "#{GEMS_DIR}/extensions/#{RUBY_PLATFORM}/#{rbmm}.0/#{name}/gem.build_complete",
          "#{sgpath}/extensions/#{RUBY_PLATFORM}/#{rbmm}.0/#{name}"
      end
      cp_r "#{GEMS_DIR}/gems/#{name}", "#{sgpath}/gems"
    end
    
    # hide shoes-bin and shoes launch script names
    puts "make_installer"
    after_install = "#{opts['app_name']}_install.sh"
    where = opts['linux_where']
    Dir.chdir(packdir) do
      mv 'shoes-bin', "#{opts['app_name']}-bin"
      File.open("#{opts['app_name']}", 'w') do |f|
        f << <<SCR
#!/bin/bash
REALPATH=`readlink -f $0`
APPPATH="${REALPATH%/*}"
if [ "$APPPATH" = "." ]; then
  APPPATH=`pwd`
fi
LD_LIBRARY_PATH=$APPPATH $APPPATH/#{opts['app_name']}-bin
SCR
      end
      chmod 0755, "#{opts['app_name']}"
      rm_rf 'shoes'
      rm_rf 'debug'
      # still inside packdir. Make an fpm after-install script
      File.open(after_install, 'w') do |f|
       f << <<SCR
#!/bin/bash
cd #{where}/bin
ln -s #{where}/lib/#{packdir}/#{opts['app_name']} .
SCR
       chmod 0755, f
      end
    end
    # now we do fpm things - lets build a bash script for debugging
    arch = `uname -m`.strip
    File.open('fpm.sh','w') do |f|
      f << <<SCR
#!/bin/bash
fpm --verbose -t deb -s dir -p #{packdir}.deb -f -n #{opts['app_name']} \\
--prefix '#{opts['linux_where']}/lib' --after-install #{packdir}/#{after_install} \\
-a #{arch} --url "#{opts['website']}" --license 'None' \\
--vendor '#{opts['publisher']}' --category #{opts['category']} \\
--description "#{opts['purpose']}" -m '#{opts['maintainer']}' #{packdir}
SCR
    end
    chmod 0755, 'fpm.sh'
  end
end
