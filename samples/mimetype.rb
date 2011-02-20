#!/usr/bin/env ruby

$: << File.expand_path(File.join(File.dirname(__FILE__), "..","lib"))

require 'rubygems'
require 'magikku'
include Magikku::Flags

def ident_file(fname)
  puts "#{fname} (#{Magikku.file(fname)}): "+
       "#{Magikku.file(fname, :flags => MIME)}"
  if File.directory?(fname)
    Dir[File.join(fname, "*")].each {|f| ident_file(f)}
  end
end

files = (ARGV.empty?)? [__FILE__] : ARGV

files.each {|file| 
  ident_file(file)
}

