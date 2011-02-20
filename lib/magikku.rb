
require 'magikku/convenience'

#begin
  require 'magikku_native'
  Magikku.class_eval{ extend(MagikkuHelpers) }
#rescue LoadError
#  require 'magikku_ffi'
#  Magikku = MagikkuFFI
#end


