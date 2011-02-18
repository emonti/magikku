require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Magic do
  before :all do 
    @klass = Magic
  end

  it_should_behave_like "Magic compiling interface"
end
