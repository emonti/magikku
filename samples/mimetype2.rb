#!/usr/bin/env ruby
$: << File.expand_path(File.join(File.dirname(__FILE__), "..","lib"))

require 'rubygems'
require 'magikku'

def ident(magik, f) 
  magik.flags = Magikku::Flags::NONE
  print "#{f} (#{magik.file(f)}) "
  magik.flags = Magikku::Flags::MIME
  puts magik.file(f)

  if File.directory?(f)
    Dir[File.join(f, "*")].each {|f2| ident(magik, f2) }
  end
end

magik = Magikku.new
Dir["*"].each do |f|
  ident(magik,f)
end
magik.close
