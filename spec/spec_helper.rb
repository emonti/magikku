$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'magikku'
require 'spec'
require 'spec/autorun'

require 'magikku_behaviors'

def sample_file(filename)
  return File.expand_path(File.join(File.dirname(__FILE__), "sample", filename))
end

Spec::Runner.configure do |config|
  
end
