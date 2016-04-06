# Linux-Shoes 

This is a Linux only project that packages a **Tight** Shoes project into a more 
user friendly deb or rpm or ... It attempts to hide the use of Shoes as
the platform. Basically it merges your app into a copy of Shoes, delete's
built in Shoes ext's and gems and merges in any Gem's you specify that you've
installed in your Linux Shoes.

The result is a distribution file (.deb)  with just enough Shoes. No manual. No irb. No debug, no
samples and the static directory is minimal. No need for Cobbler or packaging. 
No clever shy files. 

At some point in the future there might be a GUI (packaged Shoes.app) to create the yaml,
and run the build for you. Don't wait for that, it's only eye candy and if it is written
probably doesn't do what you want. 

## Requirements 

* Tight Shoes linux installed - we can't on depend Loose Shoes being built for distribution
  because it isn't.  If you happen to have Loose Shoes and Tight Shoes on the same system, now would
  be a good time create an alias for Tight Shoes and put it in your ~/.bashrc or ~/bash_profile or..
  
```
  alias tshoes=~/.shoes/walkabout/shoes
```

### fpm gem is installed

BEWARE: fpm is a shell command which is how we use it. 
It's also a ruby gem with a bin/ which means in should be installed
by the ruby at your shell prompt and accessible to that ruby. *Nothing* 
to do with the Shoes ruby version or tshoes

```
$ which gem
/home/ccoupe/.rvm/rubies/ruby-2.1.6/bin/gem

$ gem install fpm
Fetching: ffi-1.9.10.gem (100%)
Building native extensions.  This could take a while...
Successfully installed ffi-1.9.10
Fetching: clamp-0.6.5.gem (100%)
Successfully installed clamp-0.6.5
Fetching: childprocess-0.5.9.gem (100%)
Successfully installed childprocess-0.5.9
Fetching: cabin-0.8.1.gem (100%)
Successfully installed cabin-0.8.1
Fetching: backports-3.6.8.gem (100%)
Successfully installed backports-3.6.8
Fetching: arr-pm-0.0.10.gem (100%)
Successfully installed arr-pm-0.0.10
Fetching: fpm-1.4.0.gem (100%)
Successfully installed fpm-1.4.0
7 gems installed
Exiting RubyGems with exit_code 0
```

Make sure it works:
```
$ fpm -h
```

That should produce a mind numbing list of options. 

## Contents 

Git clone the github repo.
Inside is the ytm/ directory which is a sample application and there is ytm-merge.rb 
and ytm.yaml. There is a merge-lin.rb which does all the work. You'll probably
want to modify it to load the yaml file for your app. 
fix). There is a min-shoes.rb which will be copied and modified to call your starting script
instead of shoes.rb

Perhaps you're thinking "I need to know a lot". It's just scripts but you do
need to know what's in a deb or rpm or ... So know their rules.


## Usage 

`$ tshoes --ruby ytm-merge.rb`

As you know --ruby means to run Shoes as a mostly standard Ruby with some
ENV['vars'] and Constants you'll find in Shoes. Like DIR and without showing the GUI.

The **sample** just loads ytm.yaml and calls the Shoes module function
PackShoes::merge_linux in merge-lin.rb passing the opts{hash} from the ytm.yaml settings and goes
to work building a .deb (or .rpm .. or) 

The .yaml for the example is 

```
app_name: Ytm
app_version: 'Demo'
app_loc: /home/ccoupe/Projects/linux-shoes/ytm/
app_start: ytm.rb
app_png: ytm.png
purpose: 'Compute Yield to Maturity'
publisher: 'Right Wing Conspiracy'
website: 'https://github.com/Shoes3/shoes3'
maintainer: 'ccoupe@cableone.net'
license: /home/ccoupe/Projects/linux-shoes/ytm/Ytm.license
license_tag: 'open source'
category: Office
linux_where: /usr/local  # this less likely to cause problems
create_menu: true
include_exts:
 - ftsearch
 - chipmunk
include_gems:
 - sqlite3
 - nokogiri-1.6.7.1
 - ffi-1.9.10
 - rubyserial-0.2.4

```

Remember - That is just a demo!  Give it a try to see how it works. 
 
 app_loc: is where your app to package is and app_start: is the starting script
 in app_loc. app_png is your app icon in png format in app_loc. Yes, you need an icon,
 after all your trying to hide Shoes.

 If you want to include Shoes exts, ftsearch and chipmunk you would list them here.
 or delete those two lines (keep the include_exts: line)
 Unless you really do need chipmunk you shouldn't add it like I show above. Since you're not
 going to get a manual, you don't need ftsearch so delete those two lines.
 
 Gem are fun. You can include Shoes built in gems like sqlite and nokogiri as shown above
 and you can include gems you have installed in the Shoes (tshoes) that is running the script
 like ffi and rubyserial in the example. If you can't install the Gems in Shoes, then you can't include them.
 We don't automatically include dependent gems. You'll have to do that yourself with
 proper entries in your yaml file as I've shown above, 'rubyserial' requires 'ffi' for example
 
### app_name, app_version:

Read the merge-lin.rb script. It's not that big and it's yours to do what
you want.

Don't put any spaces in app_name unless your willing to fix things.
app_version isn't used in the Linux variation currently.

### fpm

I'm using fpm and since you've scanned the merge-lin.rb script you noticed
a lot of yaml entries exist just to fill in the fpm command line. fpm can do deb and
serveral other formats. Note that fpm.sh script is create before call it. You'll have 
something to look at, if things go wrong. Modify the script for rpm instead of deb is simple if 
that's what you want. 

Less obvious is that where lin-merge.rb creates fpm.sh and calls it, every thing is in Ytm-App/
(this example) so if you want more control or the fpm formats and options don't work for you, then you
can call the distribution packaging tools yourself with whatever generated config files you
like. 

 #{packdir} is a complete application. Cd into it and ./app_name:  As written, it's easier
to install #{packdir} in /usr/[local]/lib/Ytm-app. - The script appends -app because there is a ytm/
in the directory. *Because it's example.* You would be better off having  app_loc: point to a directory
that isn't next to the lin-merge.rb script.  You might have to fix a few lines of code in case the '-app`
is appended when it shouldn't be. I'm at the mercy of how github stores things for download and I wanted
to include an example you can run.  It's only a script and now it's your script.


### Could I rewrite lin-merge.rb, ytm-merge.rb in python or bash ?

Of course you could! We're just moving files around and creating some text files
so #{packdir} is something you can feed to whatever you want. Fpm needs a
Ruby (not Shoes Ruby). If you don't need fpm, then you don't need Ruby and you could rewrite
in any language you like. It's your code.

