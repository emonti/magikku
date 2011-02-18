require 'tmpdir'

shared_examples_for "Magic compiling interface" do
  


  context "Compiling rules" do
    before :each do
      @origdir =Dir.pwd
      tmpdir = Dir.mktmpdir
      Dir.chdir tmpdir

      @testrule = sample_file("ruby_magicrules")
      @expect_mgc = "#{File.basename(@testrule)}.mgc"

      File.should_not be_file(@expect_mgc)
    end

    after :each do
      File.delete @expect_mgc if File.exists?(@expect_mgc)
      Dir.chdir @origdir
    end

    it "should work using the compile convenience class method" do
      @klass.compile(@testrule).should == true
    end

    it "should work using an instantiated object" do
      m=@klass.new
      m.compile(@testrule).should == true
      m.close
    end

    it "should raise an error when compiling an invalid filename" do
      lambda{ 
        @klass.compile(sample_file('totallnonexistantfile'))
      }.should raise_error(@klass::CompileError)
    end

    it "should raise an error when compiling an syntactically incorrect filename" do
      lambda{ 
        @klass.compile(sample_file('fail_magicrules'))
      }.should raise_error(@klass::CompileError)
    end

    it "should work using the check_syntax convenience class method" do
      @klass.check_syntax(@testrule).should == true
      File.should_not be_file(@expect_mgc)
    end

    it "should work when checking syntax using an instantiated object" do
      m=@klass.new
      m.check_syntax(@testrule).should == true
      File.should_not be_file(@expect_mgc)
      m.close
    end
  end

  context "Initializing" do
    it "should initialize cleanly without arguments" do
      c=nil
      lambda { c=@klass.new }.should_not raise_error
      c.close if c
    end

    it "should initialize cleanly when a flag argument is given" do
      c=nil
      lambda { c=@klass.new(:flags => @klass::Flags::NONE) }.should_not raise_error
      c.close if c
    end

    it "should initialize cleanly when a magicfile argument is given" do
      c=nil
      lambda { c=@klass.new(:db => @testrule) }.should_not raise_error
      c.close
    end

    it "should initialize cleanly when both arguments are given" do
      c=nil
      lambda { 
        c=@klass.new(:flags => @klass::Flags::NONE, :db => @testrule) 
      }.should_not raise_error  
      c.close if c
    end


    it "should raise an error when incorrect argument types are given" do
      c=nil
      lambda { c=@klass.new(nil) }.should_not raise_error()
      c.close if c
      c=nil
      lambda { c=@klass.new(Object.new) }.should raise_error(TypeError)
      c.close if c
    end


    it "should raise an error when the wrong argument count is given" do
      c=nil
      lambda { c=@klass.new(Hash.new,Object.new) }.should raise_error(ArgumentError)
      c.close if c
    end

    it "should raise an error when a nonexistant magic file is given" do
      c=nil
      lambda { 
        c=@klass.new(:db => sample_file('totallybogus')) 
      }.should raise_error(@klass::DbLoadError)
      c.close if c
    end

    it "should raise an error when a magic file format error occurs" do
      c=nil
      lambda { 
        c=@klass.new(:db => sample_file('fail_magicrules')) 
      }.should raise_error(@klass::DbLoadError)
      c.close if c
    end
  end


end
