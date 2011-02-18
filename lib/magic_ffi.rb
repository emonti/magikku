require 'ffi'
require 'ffi/libmagic'

require 'magic/flags'
require 'magic/convenience'

# Note the implementation of this class may either be via FFI
# or via native C bindings depending on your installation and
# what version of ruby you are using.
class Magic
  # Returns the default magic database path.
  def self.path
    FFI::Libmagic.magic_getpath(nil, 0)
  end

  # Raised when an error occurs during loading of a magic database.
  class DbLoadError < StandardError
  end

  # Raised when an unexpected fatal error occurs initializing libmagic
  class InitFatal < StandardError
  end

  # Raised when an error occurs during compiling of a magic database.
  class CompileError < StandardError
  end

  # Raised when an error occurs when setting flags on a Magic object.
  class FlagError < StandardError
  end

  # Initializes a new libmagic data scanner
  #
  # @param [Fixnum,nil] flags
  #   Optional flags to magic (see Magic::Flags). 
  #   The flag values should be 'or'ed to gether with '|'. 
  #   Default: NONE
  #
  # @param [String, nil] magicfiles
  #   Optional magicfile databases or un-compiled magic files.
  #   Default: the default system magic.mgc file.
  #
  # @see See Magic::Flags and libmagic(3) manpage
  # @see dbload()
  def initialize(flags=nil, magicfiles=nil)
    flags ||= Magic::Flags::NONE
    @_cookie = FFI::Libmagic.magic_open(flags)
    if @_cookie.null?
      raise(InitFatal, "magic_open(#{flags}) returned a null pointer")
    end

    dbload(nil)
  end

  # Close the libmagic data scanner handle when you are finished with it
  def close
    FFI::Libmagic.magic_close(@_cookie)
  end

  # Analyzes file contents against the magicfile database
  #
  # @param filename 
  #   The path to a file to inspect
  # @return [String] 
  #   A textual description of the contents of the file
  def file(filename)
    return nil if filename.nil?
    FFI::Libmagic.magic_file(@_cookie, filename)
  end

  # Analyzes a string buffer against the magicfile database
  #
  # @param filename 
  #   The string buffer to inspect
  # @return [String] 
  #   A textual description of the contents the string
  def string(str)
    p = FFI::MemoryPointer.new(str.size)
    p.write_string_length(str, str.size)
    FFI::Libmagic.magic_buffer(@_cookie, p, str.size)
  end


  # Used to load one or more magic databases.
  # 
  # @param magicfiles
  #   One or more filenames seperated by colons. If nil, the default database
  #   is loaded.
  #   If uncompiled magic files are specified, they are compiled on the fly
  #   but they do not generate new .mgc files as with the compile method.
  #   Multiple files be specified by seperating them with colons.
  #
  # @raise [DbLoadError] if an error occurred loading the database(s)
  def dbload(magicfiles)
    if FFI::Libmagic.magic_load(@_cookie, magicfiles) != 0
      raise(DbLoadError, "Error loading db: #{magicfiles}" << lasterror())
    else
      return true
    end
  end

  # Sets flags for the magic analyzer handle.
  #
  # @param flags
  #   Flags to to set for magic. See Magic::Flags and libmagic(3) manpage. 
  #   The flag values should be 'or'ed together with '|'. 
  #   Using 0 will clear all flags.
  def flags=(flags)
    if FFI::LibMagic.magic_setflags(@_cookie, flags) < 0
      raise(FlagError, lasterror())
    end
  end

  # Can be used to compile magic files. This does not load files, however. You must
  # use dbload for that.
  #
  # Note: Errors and warnings may be displayed on stderr.
  #
  # @param [String,nil] filename
  #   A colon seperated list of filenames or a single filename. 
  #   The compiled files created are generated in the current directory using 
  #   the basename(1) of each file argument with ".mgc" appended to it.
  #   Directory names can be compiled, in which case the contents of the directory
  #   will be compiled together as a single .mgc file.
  #   nil compiles the default database.
  #
  # @return [true] if everything went well.
  # @raise [CompileError] if an error occurred.
  def compile(filenames)
    if FFI::Libmagic.magic_compile(@_cookie, filenames) != 0
      raise(CompileError, "Error compiling #{filenames.inspect}:" << lasterror())
    else
      return true
    end
  end

  # Can be used to check the validity of magic files before compiling them.
  # This is basically a dry-run that can be used before compiling magicfile 
  # databases.
  #
  # Note: Errors and warnings may be displayed on stderr.
  #
  # @param [String,nil] filename
  #   A colon seperated list of filenames or a single file. nil checks the
  #   default database.
  #
  # @return [true,false] Indicates whether the check was successful.
  def check_syntax(filenames=nil)
    return (FFI::Libmagic.magic_check(@_cookie, filenames) == 0)
  end

  private
    def lasterror
      FFI::Libmagic.magic_error(@_cookie)
    end

    def lasterrno
      FFI::Libmagic.magic_errno(@_cookie)
    end

end
