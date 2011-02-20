
module MagicHelpers
  # A convenience method for checking syntax of magicdb files.
  #
  # Note: syntax errors and warnings may be displayed on stderr.
  #
  # @param String fname
  #   Filename or directory to compile
  #
  # @param Hash params
  #   A hash of parameters to Magic.new()
  #
  # @return true,false
  def check_syntax(fname, params={})
    m=new(params)
    begin
      return m.check_syntax(fname)
    ensure
      m.close()
    end
  end

  # A convenience method for compiling magicdb files.
  #
  # @param String fname
  #   Filename or directory to compile
  #
  # @param Hash params
  #   A hash of parameters to Magic.new()
  #
  # @return true
  #
  # @raise Magic::CompileError if an error occurs
  def compile(fname, params={})
    m=new(params)
    begin
      return m.compile(fname)
    ensure
      m.close()
    end
  end

  # A convenience method for identifying file contents
  #
  # @param String fname
  #   Filename to identify
  #
  # @param Hash params
  #   A hash of parameters to Magic.new()
  #
  # @return String
  #   Identification of the file contents.
  def file(fname, params={})
    m=new(params)
    begin
      return m.file(fname)
    ensure
      m.close()
    end
  end

  # A convenience method for identifying string contents
  #
  # @param String buf
  #   String contents to identify
  #
  # @param Hash params
  #   A hash of parameters to Magic.new()
  #
  # @return String
  #   Identification of the string.
  def string(buf, params={})
    m=new(params)
    begin
      return m.string(buf)
    ensure
      m.close()
    end
  end
end


