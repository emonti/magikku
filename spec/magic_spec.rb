require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'tmpdir'

describe Magic do
  context "Compiling" do
    before :each do
      @origdir =Dir.pwd
      tmpdir = Dir.mktmpdir
      Dir.chdir tmpdir

      @testrule = sample_file("ruby_magicrules")
      @expect_mgc = "#{File.basename(@testrule)}.mgc"

      File.should_not be_file(@expect_mgc)
    end

    after :each do
      File.should be_file(@expect_mgc)
      File.delete @expect_mgc
      Dir.chdir @origdir
    end

    it "should compile rules using the Magic.compile() convenience method" do
      Magic.compile(@testrule)
    end

    it "should compile rules from a Magic object" do
      m=Magic.new
      m.compile(@testrule).should == true
      m.close
    end
  end
end
