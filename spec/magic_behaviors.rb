require 'tmpdir'

shared_examples_for "Magic compiling interface" do

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

  context "An Instantiated Object" do
    before :each do
      @magic=@klass.new()
    end

    after :each do
      @magic.close if not @magic.closed?
    end

    it "should be able to identify file buffers" do
      @magic.file(sample_file("test.txt")).should == "ASCII text"
      @magic.file(sample_file("test.c")).should == "ASCII C program text"
    end

    it "should be able to identify string buffers" do
      @magic.string(File.read sample_file("test.txt")).should == "ASCII text"
      @magic.string(File.read sample_file("test.c")).should == "ASCII C program text"
      @magic.string("\x01\x02\x03\x04").should == "data"
    end

    it "should be able to use flag options" do
      @magic.flags = @klass::Flags::MIME
      @magic.string(File.read sample_file("test.txt")).should == "text/plain; charset=us-ascii"
      @magic.string(File.read sample_file("test.c")).should == "text/x-c; charset=us-ascii"
      @magic.string("\x01\x02\x03\x04").should == "application/octet-stream; charset=binary"
    end

    it "should raise an error if a nonexistant file is specified to inspect" do
      lambda{
        @magic.file(sample_file('totallybogusfile'))
      }.should raise_error(Errno::ENOENT)
    end

    it "should raise an error when an incorrect object is passed to file()" do
      lambda{ @magic.file(Object.new) }.should raise_error(TypeError)
      lambda{ @magic.file(nil) }.should raise_error(TypeError)
    end

    it "should raise an error when an incorrect object is passed to file()" do
      lambda{ @magic.string(Object.new) }.should raise_error(TypeError)
      lambda{ @magic.string(nil) }.should raise_error(TypeError)
    end

    it "should be able to load magicrules databases" do
      test_str="THISISARUBYMAGICTEST blah blah\nblah\x01\x02"
      @magic.string(test_str).should_not == "RUBYMAGICTESTHIT"
      @magic.dbload(sample_file('test_magicrule'))
      @magic.string(test_str).should == "RUBYMAGICTESTHIT"
    end

    it "should load the default magicrules database when nil is loaded" do
      test_str="THISISARUBYMAGICTEST blah blah\nblah\x01\x02"
      @magic.string(test_str).should_not == "RUBYMAGICTESTHIT"
      @magic.string(test_str).should == "data"
      @magic.dbload(nil)
      @magic.string(test_str).should_not == "RUBYMAGICTESTHIT"
      @magic.string(test_str).should == "data"
    end

    it "should raise an error when loading an invalid filename" do
      lambda{ 
        @magic.dbload(sample_file('totallybogusfile')) 
      }.should raise_error(@klass::DbLoadError)
    end

    it "should raise an error when an incorrect object is passed to dbload()" do
      lambda{ 
        @magic.dbload(Object.new)
      }.should raise_error(@argerror)
    end

    it "should be able to be closed" do
      lambda { @magic.close }.should_not raise_error
      @magic.should be_closed
    end

    it "should correctly indicate whether it is already closed" do
      @magic.should_not be_closed
      @magic.close
      @magic.should be_closed
      lambda { @magic.close }.should_not raise_error
    end

    it "should not be usable after it is closed" do
      @magic.close
      lambda{
        @magic.file(File.expand_path(__FILE__))
      }.should raise_error(@klass::ClosedError)

      lambda{
        @magic.string("foo")
      }.should raise_error(@klass::ClosedError)

      lambda{
        @magic.check_syntax(sample_file('fail_magicrules')) 
      }.should raise_error(@klass::ClosedError)

      lambda{ 
        @magic.compile(sample_file('fail_magicrules')) 
      }.should raise_error(@klass::ClosedError)

      lambda{ 
        @magic.check_syntax(sample_file('ruby_magicrules')) 
      }.should raise_error(@klass::ClosedError)

      lambda{ 
        @magic.compile(sample_file('ruby_magicrules')) 
      }.should raise_error(@klass::ClosedError)

    end
  end

  context "Compiling And Convenience Methods" do
    before :all do
      @tmpdir = Dir.mktmpdir
    end

    before :each do
      @origdir =Dir.pwd
      Dir.chdir @tmpdir

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
      @klass.check_syntax(@testrule).should == true
      @klass.check_syntax(sample_file('fail_magicrules')).should == false
    end

    it "should work when checking syntax using an instantiated object" do
      m=@klass.new
      m.check_syntax(@testrule).should == true
      File.should_not be_file(@expect_mgc)
      m.check_syntax(sample_file('fail_magicrules')).should == false
      m.close
    end

    it "should return false when checking an invalid filename" do
      @klass.check_syntax(sample_file('totallnonexistantfile')).should == false
      m=@klass.new
      m.check_syntax(sample_file('totallnonexistantfile')).should == false
      m.close
    end

    it "should check the default database when given a nil filename" do
      @klass.check_syntax(nil).should == true
      m=@klass.new
      m.check_syntax(nil).should == true
      m.close
    end

    it "should return the default magic database with path()" do
      @klass.path.should be_kind_of(String)
      @klass.path.should_not be_empty
    end
  end

end
