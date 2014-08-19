module Socketry
  
  class SocketryError < Exception
  end
  
  class InternalError < SocketryError
  end
  
  class NotImplemented < SocketryError
  end
  
end