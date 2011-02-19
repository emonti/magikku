require 'ffi'
require 'ffi/libmagic'

require 'magic/convenience'

# Note the implementation of this class may either be via FFI
# or via native C bindings depending on your installation and
# what version of ruby you are using.
class MagicFFI
  extend MagicHelpers

  # Defines various flags that can be passed when creating a magic scan object
  # using Magic.new or afterwards using Magic.flags=
  module Flags
    # No flags
    NONE              = 0x000000

    # Turn on debugging
    DEBUG             = 0x000001

    # Follow symlinks
    SYMLINK           = 0x000002

    # Check inside compressed files
    COMPRESS          = 0x000004

    # Look at the contents of devices
    DEVICES           = 0x000008

    # Return the MIME type
    MIME_TYPE         = 0x000010

    # Return all matches
    CONTINUE          = 0x000020

    # Print warnings to stderr
    CHECK             = 0x000040

    # Restore access time on exit
    PRESERVE_ATIME    = 0x000080

    # Don't translate unprintable chars
    RAW               = 0x000100

    # Handle ENOENT etc as real errors
    ERROR             = 0x000200

    # Return the MIME encoding
    MIME_ENCODING     = 0x000400

    # alias for (MAGIC_MIME_TYPE|MAGIC_MIME_ENCODING)
    MIME              = (MIME_TYPE|MIME_ENCODING)

    # Return the Apple creator and type
    APPLE             = 0x000800

    # Don't check for compressed files
    NO_CHECK_COMPRESS = 0x001000

    # Don't check for tar files
    NO_CHECK_TAR      = 0x002000

    # Don't check magic entries
    NO_CHECK_SOFT     = 0x004000

    # Don't check application type
    NO_CHECK_APPTYPE  = 0x008000

    # Don't check for elf details
    NO_CHECK_ELF      = 0x010000

    # Don't check for text files
    NO_CHECK_TEXT     = 0x020000

    # Don't check for cdf files
    NO_CHECK_CDF      = 0x040000

    # Don't check tokens
    NO_CHECK_TOKENS   = 0x100000

    # Don't check text encodings
    NO_CHECK_ENCODING = 0x200000 

    # alias for NO_CHECK_TEXT
    NO_CHECK_ASCII   = NO_CHECK_TEXT 
  end

  # Returns the default magic database path.
  def self.path
    FFI::Libmagic.magic_getpath(nil, 0)
  end

  # A base class for other Magic error types
  class MagicError < StandardError
  end

  # Raised when an error occurs during loading of a magic database.
  class DbLoadError < MagicError
  end

  # Raised when an unexpected fatal error occurs initializing libmagic
  class InitFatal < MagicError
  end

  # Raised when an error occurs during compiling of a magic database.
  class CompileError < MagicError
  end

  # Raised when an error occurs when setting flags on a Magic object.
  class FlagError < MagicError
  end

  # Raised when an error occurs when setting flags on a Magic object.
  class ClosedError < MagicError
  end

  # Initializes a new libmagic data scanner
  #
  # @param [Hash,nil] params
  #   A hash of parameters or nil for defaults.
  #
  # @option params [Fixnum,nil] :flags
  #   Optional flags to magic (see MagicFFI::Flags). 
  #   The flag values should be 'or'ed to gether with '|'. 
  #   Default: NONE
  #
  # @option params [String, nil] :db
  #   Optional magicfile databases or un-compiled magic files.
  #   Default: the default system magic.mgc file.
  #
  # @see See MagicFFI::Flags and libmagic(3) manpage
  # @see dbload()
  def initialize(param = nil)
    param ||= {}
    raise(TypeError, "Invalid Type for params") if not param.is_a?(Hash)

    flags = param[:flags] || Flags::NONE
    raise(TypeError, "flags must be a Fixnum") if not flags.is_a?(Fixnum)

    db = param[:db]
    raise(TypeError, "db must be nil or a String") if db and not db.is_a?(String)

    @_cookie = FFI::Libmagic.magic_open(flags)
    if @_cookie.null?
      raise(InitFatal, "magic_open(#{flags}) returned a null pointer")
    end

    if FFI::Libmagic.magic_load(_cookie, db) != 0
      err = lasterror()
      FFI::Libmagic.magic_close(_cookie)
      raise(DbLoadError, "Error loading db: #{db.inspect} " << err)
    end
  end

  # Close the libmagic data scanner handle when you are finished with it
  def close
    FFI::Libmagic.magic_close(_cookie) unless @closed

    @closed = true
    return nil
  end

  def closed?
    (@closed == true)
  end

  # Analyzes file contents against the magicfile database
  #
  # @param filename 
  #   The path to a file to inspect
  # @return [String] 
  #   A textual description of the contents of the file
  def file(filename)
    File.stat(filename)
    raise(TypeError, "filename must not be nil") if filename.nil?
    FFI::Libmagic.magic_file(_cookie, filename)
  end

  # Analyzes a string buffer against the magicfile database
  #
  # @param filename 
  #   The string buffer to inspect
  # @return [String] 
  #   A textual description of the contents the string
  def string(str)
    raise(TypeError, "wrong argument type #{str.class} (expected String)") unless str.is_a?(String)
    p = FFI::MemoryPointer.new(str.size)
    p.write_string_length(str, str.size)
    FFI::Libmagic.magic_buffer(_cookie, p, str.size)
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
    if FFI::Libmagic.magic_load(_cookie, magicfiles) != 0
      raise(DbLoadError, "Error loading db: #{magicfiles.inspect} " << lasterror())
    else
      return true
    end
  end

  # Sets flags for the magic analyzer handle.
  #
  # @param flags
  #   Flags to to set for magic. See MagicFFI::Flags and libmagic(3) manpage. 
  #   The flag values should be 'or'ed together with '|'. 
  #   Using 0 will clear all flags.
  def flags=(flags)
    if FFI::Libmagic.magic_setflags(_cookie, flags) < 0
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
  #
  # @raise [CompileError] if an error occurred.
  def compile(filenames)
    if FFI::Libmagic.magic_compile(_cookie, filenames) != 0
      raise(CompileError, "Error compiling #{filenames.inspect}: " << lasterror())
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
    return (FFI::Libmagic.magic_check(_cookie, filenames) == 0)
  end

  private
    def _cookie
      if @closed
        raise(ClosedError, "This magic cookie is closed and can no longer be used")
      else
        @_cookie
      end
    end

    def lasterror
      FFI::Libmagic.magic_error(_cookie)
    end

    def lasterrno
      FFI::Libmagic.magic_errno(_cookie)
    end

end
