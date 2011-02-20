require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Magikku do
  before :all do 
    @klass = Magikku
    @argerror = TypeError
  end

  it_should_behave_like "Magikku compiling interface"
end
