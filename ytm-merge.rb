# run this with cshoes.exe --ruby ytm-merge.rb
require 'yaml'
opts = YAML.load_file('ytm.yaml')
here = Dir.getwd
home = ENV['HOME']
puts "gemsdir: |#{ENV['GEMS_DIR']}|"
GEMS_DIR = File.join(home, '.shoes','+gem')
puts "DIR = #{DIR}"
puts "GEMS_DIR = #{GEMS_DIR}"
puts "Here = #{here}"
ENV['GEMS_DIR'] = GEMS_DIR
require_relative 'merge-lin'
#PackShoes::merge_linux opts
