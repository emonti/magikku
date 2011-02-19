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

  describe MagicFFI::Flags do
    context "Checking Values" do
      Magic::Flags.constants.each do |const|
        it "should have the correct value for #{const}" do
          Magic::Flags.const_get(const).should == MagicFFI::Flags.const_get(const)
        end
      end
    end
  end
else
  describe "C Binding" do
    it "was not compiled" do
      pending "unable to test C bindings"
    end
  end
end
