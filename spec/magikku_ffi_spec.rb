require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'magikku_ffi'

if Magikku != MagikkuFFI

  describe MagikkuFFI do
    before :all do 
      @klass = MagikkuFFI
      @argerror = ArgumentError
    end

    it_should_behave_like "Magikku compiling interface"
  end

  describe MagikkuFFI::Flags do
    context "Checking Values" do
      Magikku::Flags.constants.each do |const|
        it "should have the correct value for #{const}" do
          Magikku::Flags.const_get(const).should == MagikkuFFI::Flags.const_get(const)
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
