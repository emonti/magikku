require 'ffi'

module FFI
  module Libmagic
    extend FFI::Library
    ffi_lib 'magic'

    typedef :pointer, :magic_t

    # magic_t magic_open(int flags);
    attach_function :magic_open, [:int], :magic_t

    # void magic_close(magic_t cookie);
    attach_function :magic_close, [:magic_t], :void

    #  const char * magic_error(magic_t cookie);
    attach_function :magic_error, [:magic_t], :string

    #  int magic_errno(magic_t cookie);
    attach_function :magic_errno, [:magic_t], :int

    #  const char * magic_file(magic_t cookie, const char *filename);
    attach_function :magic_file, [:magic_t, :string], :string

    #  const char * magic_buffer(magic_t cookie, const void *buffer, size_t length);
    attach_function :magic_buffer, [:magic_t, :pointer, :size_t], :string

    #  int magic_setflags(magic_t cookie, int flags);
    attach_function :magic_setflags, [:magic_t, :int], :int

    #  int magic_check(magic_t cookie, const char *filename);
    attach_function :magic_check, [:magic_t, :string], :int

    #  int magic_compile(magic_t cookie, const char *filename);
    attach_function :magic_compile, [:magic_t, :string], :int

    #  int magic_load(magic_t cookie, const char *filename);
    attach_function :magic_load, [:magic_t, :string], :int

    # NOTE magic_getpath not doc'd in libmagic(3), 
    #      not available in earlier versions?
    #
    # const char * int magic_getpath(const char *magicfile, int action)
    attach_function :magic_getpath, [:string, :int], :string
  end
end
