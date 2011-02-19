#include "ruby.h"
#include <magic.h>
#include <stdio.h>

VALUE c_magic = Qnil;
VALUE m_flags = Qnil;

VALUE e_MagicError = Qnil;
VALUE e_InitFatal = Qnil;
VALUE e_DbLoadError = Qnil;
VALUE e_CompileError = Qnil;
VALUE e_FlagError = Qnil;
VALUE e_ClosedError = Qnil;




/* Internal function to check whether a handle is already closed */
magic_t 
_check_closed(VALUE self) {
  magic_t ret = NULL;
  if (rb_iv_get(self, "@closed") != Qtrue) 
    Data_Get_Struct(self, void, ret);
  return (magic_t) ret;
}

#define CLOSED_ERR_MSG "This magic cookie is closed and can no longer be used"

/* call-seq: magic=Magic.new(:db => '/path/to/some/magic.mgc', :flags => Magic::Flags::None)
 *
 * Instantiates a new Magic cookie which we can use to load magic databases,
 * compile new databases, and identify files and string buffers.
 *
 * @param [Hash, nil] params
 *      A hash of optional parameters to pass to the initializer.
 *
 * @option params [String] :db
 *      One or more magic databases to load on initialization. If nothing
 *      is specified, the default database will be used.
 *
 * @option params [Fixnum] :flags
 *      Initialization flags to configure libmagic. 
 *
 * @see Magic::Flags and libmagic(3)
 *
 * @raise [Magic::DbLoadError] 
 *      An error is raised if the database cannot be loaded.
 *
 * @raise [Magic::InitFatal]
 *      An error is raised if an unknown error is encountered initializing
 *      the cookie with libmagic.
 */
VALUE 
rb_magic_initialize(int argc, VALUE *argv, VALUE klass) {
  VALUE params = Qnil;
  VALUE flags_val, db_val;
  magic_t cookie; 
  int flags = 0;
  char *magicf = NULL, *error=NULL;

  rb_scan_args(argc, argv, "01", &params);

  if (params != Qnil) {
    Check_Type(params, T_HASH);

    flags_val=rb_hash_aref(params, ID2SYM(rb_intern("flags")));
    if (flags_val != Qnil) {
      Check_Type(flags_val, T_FIXNUM);
      flags = NUM2INT(flags_val);
    }

    db_val=rb_hash_aref(params, ID2SYM(rb_intern("db")));
    if (db_val != Qnil) {
      Check_Type(db_val, T_STRING);
      magicf = RSTRING_PTR(db_val);
    }
  }

  if ((cookie=magic_open(flags))==NULL)
    rb_raise(e_InitFatal, "magic_open(%i) returned a null pointer", flags);

  if (magic_load(cookie, magicf) != 0) {
    error = magic_error(cookie);
    magic_close(cookie);
    rb_raise(e_DbLoadError, "Error loading db \"%s\": %s", magicf, error);
  }

  return Data_Wrap_Struct(klass, NULL, NULL, cookie);
}


/* call-seq: Magic.path
 *
 * Returns the default magic database path.
 */
VALUE 
rb_magic_path(VALUE klass) {
  const char * path = magic_getpath(NULL, 0);
  return rb_str_new2(path);
}

/* call-seq: magic.dbload("/path/to/magic.mgc:/path/to/magicdir/") -> true
 *
 * Used to load one or more magic databases.
 * 
 * @param magicfiles
 *   One or more filenames seperated by colons. If nil, the default database
 *   is loaded.
 *   If uncompiled magic files are specified, they are compiled on the fly
 *   but they do not generate new .mgc files as with the compile method.
 *   Multiple files be specified by seperating them with colons.
 *
 * @raise [DbLoadError] if an error occurred loading the database(s)
 */
VALUE 
rb_magic_dbload(VALUE self, VALUE magicf_val) {
  magic_t cookie = _check_closed(self);
  char *magicf;

  if(!cookie)             rb_raise(e_ClosedError, CLOSED_ERR_MSG);
  if(magicf_val != Qnil)  Check_Type(magicf_val, T_STRING);

  magicf = RSTRING_PTR(magicf_val);

  Data_Get_Struct(self, void, cookie);

  if (magic_load(cookie, magicf) != 0)
    rb_raise(e_DbLoadError, "Error loading db \"%s\": %s", magicf, magic_error(cookie));

  return Qtrue;
}

/* call-seq: magic.close -> nil
 *
 * Close the libmagic data scanner handle when you are finished with it
 *
 * Note that magic handles are never closed automatically, even when
 * garbage collection occurs.
 */
VALUE 
rb_magic_close(VALUE self) {
  magic_t cookie = _check_closed(self);

  if(cookie) magic_close(cookie);
  rb_iv_set(self, "@closed", Qtrue);

  return Qnil;
}

/* call-seq: magic.closed? -> true|false
 *
 * Indicates whether the magic cookie has been closed
 *
 * @return [true,false]
 */
VALUE 
rb_magic_is_closed(VALUE self) {
  VALUE ret = rb_iv_get(self, "@closed");
  if (ret == Qnil) ret = Qfalse;
  return ret;
}

/* call-seq: magic.file("somefile") -> "file description"
 *
 * Analyzes file contents against the magicfile database
 *
 * @param filename 
 *   The path to a file to inspect
 * @return [String] 
 *   A textual description of the contents of the file
 */
VALUE 
rb_magic_file(VALUE self, VALUE filename) {
  const char *ret;
  magic_t cookie = _check_closed(self);

  if (!cookie)          rb_raise(e_ClosedError, CLOSED_ERR_MSG);
  if (filename != Qnil) Check_Type(filename, T_STRING);

  ret=magic_file(cookie, RSTRING_PTR(filename));
  return rb_str_new2(ret);
}

VALUE rb_magic_string(VALUE self, VALUE string) {
  const char *ret;
  magic_t cookie = _check_closed(self);
  if (!cookie)          rb_raise(e_ClosedError, CLOSED_ERR_MSG);
  if (string != Qnil)   Check_Type(string, T_STRING);

  ret=magic_buffer(cookie, RSTRING_PTR(string), RSTRING_LEN(string));
  return rb_str_new2(ret);
}

VALUE rb_magic_compile(VALUE self, VALUE magicf) {
  char *_magicf;
  magic_t cookie = _check_closed(self);

  if (!cookie)          rb_raise(e_ClosedError, CLOSED_ERR_MSG);
  if (magicf != Qnil)   Check_Type(magicf, T_STRING);

  _magicf = RSTRING_PTR(magicf);

  if (magic_compile(cookie, _magicf) == 0) return Qtrue;
  else rb_raise(e_CompileError, 
        "Error compiling \"%s\": %s", _magicf, magic_error(cookie));
}

VALUE rb_magic_check_syntax(VALUE self, VALUE magicf) {
  magic_t cookie = _check_closed(self);

  if (!cookie) rb_raise(e_ClosedError, CLOSED_ERR_MSG);
  if (magicf != Qnil) Check_Type(magicf, T_STRING);

  if (magic_check(cookie, RSTRING_PTR(magicf)) == 0) return Qtrue;
  else return Qfalse;
}

VALUE rb_magic_set_flags(VALUE self, VALUE flags) {
  magic_t cookie = _check_closed(self);
  return Qnil;
}

void Init_magic_native() {
  /* The Magic class is both our interface to libmagic functionality
   * as well as the top-level namespace */
  c_magic = rb_define_class("Magic", rb_cObject);
  rb_define_singleton_method(c_magic, "new", rb_magic_initialize, -1);
  rb_define_method(c_magic, "close", rb_magic_close, 0);
  rb_define_method(c_magic, "closed?", rb_magic_is_closed, 0);
  rb_define_method(c_magic, "compile", rb_magic_compile, 1);
  rb_define_method(c_magic, "check_syntax", rb_magic_check_syntax, 1);
  rb_define_method(c_magic, "file", rb_magic_file, 1);
  rb_define_method(c_magic, "string", rb_magic_string, 1);

  /* The flags module contains only constants exposed to ruby */
  m_flags = rb_define_module_under(c_magic, "Flags");
  rb_define_const(m_flags, "NONE", INT2FIX(MAGIC_NONE));
  rb_define_const(m_flags, "DEBUG", INT2FIX(MAGIC_DEBUG));
  rb_define_const(m_flags, "SYMLINK", INT2FIX(MAGIC_SYMLINK));
  rb_define_const(m_flags, "COMPRESS", INT2FIX(MAGIC_COMPRESS));
  rb_define_const(m_flags, "DEVICES", INT2FIX(MAGIC_DEVICES));
  rb_define_const(m_flags, "MIME_TYPE", INT2FIX(MAGIC_MIME_TYPE));
  rb_define_const(m_flags, "CONTINUE", INT2FIX(MAGIC_CONTINUE));
  rb_define_const(m_flags, "CHECK", INT2FIX(MAGIC_CHECK));
  rb_define_const(m_flags, "PRESERVE_ATIME", INT2FIX(MAGIC_PRESERVE_ATIME));
  rb_define_const(m_flags, "RAW", INT2FIX(MAGIC_RAW));
  rb_define_const(m_flags, "ERROR", INT2FIX(MAGIC_ERROR));
  rb_define_const(m_flags, "MIME_ENCODING", INT2FIX(MAGIC_MIME_ENCODING));
  rb_define_const(m_flags, "MIME", INT2FIX(MAGIC_MIME));
  rb_define_const(m_flags, "APPLE", INT2FIX(MAGIC_APPLE));
  rb_define_const(m_flags, "NO_CHECK_COMPRESS", INT2FIX(MAGIC_NO_CHECK_COMPRESS));
  rb_define_const(m_flags, "NO_CHECK_TAR", INT2FIX(MAGIC_NO_CHECK_TAR));
  rb_define_const(m_flags, "NO_CHECK_SOFT", INT2FIX(MAGIC_NO_CHECK_SOFT));
  rb_define_const(m_flags, "NO_CHECK_APPTYPE", INT2FIX(MAGIC_NO_CHECK_APPTYPE));
  rb_define_const(m_flags, "NO_CHECK_ELF", INT2FIX(MAGIC_NO_CHECK_ELF));
  rb_define_const(m_flags, "NO_CHECK_TEXT", INT2FIX(MAGIC_NO_CHECK_TEXT));
  rb_define_const(m_flags, "NO_CHECK_CDF", INT2FIX(MAGIC_NO_CHECK_CDF));
  rb_define_const(m_flags, "NO_CHECK_TOKENS", INT2FIX(MAGIC_NO_CHECK_TOKENS));
  rb_define_const(m_flags, "NO_CHECK_ENCODING", INT2FIX(MAGIC_NO_CHECK_ENCODING));
  rb_define_const(m_flags, "NO_CHECK_ASCII", INT2FIX(MAGIC_NO_CHECK_ASCII));

  /* define our exception classes... */
  e_MagicError = rb_define_class_under(c_magic, "MagicError", rb_eStandardError);
  e_InitFatal = rb_define_class_under(c_magic, "InitFatal", e_MagicError);
  e_DbLoadError = rb_define_class_under(c_magic, "DbLoadError", e_MagicError);
  e_CompileError = rb_define_class_under(c_magic, "CompileError", e_MagicError);
  e_FlagError = rb_define_class_under(c_magic, "FlagError", e_MagicError);
  e_ClosedError = rb_define_class_under(c_magic, "ClosedError", e_MagicError);

}
