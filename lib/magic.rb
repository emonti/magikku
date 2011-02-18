
require 'magic/convenience'

begin
  require 'magic_native'
  Magic.class_eval{ extend(MagicHelpers) }
rescue LoadError
  require 'magic_ffi'
  Magic = MagicFFI
end


