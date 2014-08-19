require 'socketry/error'

module Socketry
  
  class ProtoError < SocketryError
  end
  
  class BadRequest < ProtoError
  end
  
  class BadIdentity < ProtoError
  end
  
  class Unchanged < ProtoError
  end
  
  class BadResponse < ProtoError
  end
  
  class NotFound < ProtoError
  end
  
  class ConnectionFailure < ProtoError
  end
  
  module Proto
    
    ##########
    
    NAME = 'Socketry'.freeze
    VERSION = '1.0'.freeze
    
    HTTP_SIGNATURE_FIELD = 'X-Socketry-Protocol'.freeze
    
    HEAD_FIELD = 'a'.freeze
    BODY_FIELD = 'b'.freeze
    ERROR_FIELD = 'e'.freeze

    NOW_FIELD = 'Now'.freeze
    SINCE_FIELD = 'Since'.freeze
    
    ADD_FIELD = '+'.freeze
    REMOVE_FIELD = '-'.freeze
    
    MESSAGES_FIELD = 'Messages'.freeze

    def self.signature
      @@signature ||= [NAME, VERSION].join('/')
    end
    
    RSA_KEY_SIZE_IN_BITS = 2048
    CIPHER_TYPE = 'AES-256-CBC'.freeze
    
    MAX_PIECE_COUNT = 4096
    # MAX_PIECE_SIZE = 1024*1024
    MAX_PIECE_SIZE = 1024*256
    CHECKSUM_TYPE = :md5
    
    ##########
    
    module Master
      NEW_USER_PATH = '/user/new'

      PING_PATH = '/node/update'
      NEW_NODE_PATH = '/node/new'

      ANNOUNCE_MESSAGE_PATH = '/message/announce'
      
      CONTACTS_FIELD = 'Contacts'.freeze
    end
    
    module Message
      UID_FIELD = 'Message'.freeze
      TO_FIELD = 'To'.freeze
    end
    
    module User
      LOGIN_FIELD = 'Login'.freeze
      PASSWORD_FIELD = 'Password'.freeze
    end
    
    module Node
      UID_FIELD = 'Node'.freeze
      OTHER_UID_FIELD = 'OtherNode'.freeze
      PUBLIC_KEY_FIELD = 'PublicKey'.freeze
      MODULUS_FIELD = 'Mod'.freeze
      EXPONENT_FIELD = 'Exp'.freeze
      
      HOST_FIELD = 'Host'.freeze
      PORT_FIELD = 'Port'.freeze
      
      DEFAULT_PORT = 3000
      
      DOWNLOAD_PIECE_PATH = '/service/download'
    end
    
    module Tracker
      ANNOUNCE_ASSET_PATH = '/tracker/asset/announce'
      ACTIVATE_ASSETS_PATH = '/tracker/asset/activate'
      TRACK_ASSET_PATH = '/tracker/asset/track'
      
      ASSET_FIELD = 'Asset'.freeze
      ASSETS_FIELD = 'Assets'.freeze
      
      PIECE_FIELD = 'Piece'.freeze
      PIECES_FIELD = 'Pieces'.freeze
      
      MAX_NODE_COUNT = 10
      NODES_FIELD = 'Nodes'.freeze
    end
    
    ##########
    
  end
end
