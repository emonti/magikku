require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'magic_ffi'

if Magic != MagicFFI

  describe MagicFFI do
    before :all do 
      @klass = MagicFFI
      @argerror = ArgumentError
    end

    it_should_behave_like "Magic compiling interface"
  end
end
