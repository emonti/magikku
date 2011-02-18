
module MagicHelpers
  # A convenience method for checking syntax files using a Magic object
  # which is created and closed just for that purpose.
  #
  # Arguments are passed directly to Magic.check_syntax
  def check_syntax(*args)
    m=new()
    begin
      return m.check_syntax(*args)
    ensure
      m.close()
    end
  end

  # A convenience method for compiling files using a Magic object
  # which is created and closed just for that purpose.
  #
  # Arguments are passed directly to Magic.compile
  def compile(*args)
    m=new()
    begin
      return m.compile(*args)
    ensure
      m.close()
    end
  end
end


