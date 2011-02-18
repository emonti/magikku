
require 'magic/flags'
require 'magic_ffi'

class Magic
  # A convenience method for compiling files using a Magic object
  # which is created and closed just for that purpose.
  #
  # Arguments are passed directly to Magic.compile
  def self.compile(*args)
    m=new()
    begin
      return m.compile(*args)
    ensure
      m.close()
    end
  end


end
