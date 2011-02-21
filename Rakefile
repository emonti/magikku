require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "magikku"
    gem.summary = "Ruby bindings for the libmagic(3) library"
    gem.description = "Ruby bindings to the libmagic(3) library for identifying unknown files and data contents"
    gem.email = "esmonti@gmail.com"
    gem.homepage = "http://github.com/emonti/magikku"
    gem.authors = ["Eric Monti"]
    gem.add_development_dependency "ffi", ">= 0.5.0"
    gem.add_development_dependency "rspec", ">= 1.2.9"

    gem.extra_rdoc_files += Dir["ext/**/*.c"]
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

require 'rake/extensiontask'
Rake::ExtensionTask.new("magikku_native")

CLEAN.include("doc")
CLEAN.include("rdoc")
CLEAN.include("coverage")
CLEAN.include("tmp")
CLEAN.include("lib/*.bundle")
CLEAN.include("lib/*.so")

task :spec => [:check_dependencies, :compile]

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "magikku #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.rdoc_files.include('ext/**/*.c')
end

require 'yard'
YARD::Rake::YardocTask.new


