require 'socketry/proto'
require 'socketry/client/node_base'

module Socketry
  module Client
    
    ##########
    
    class DownloadClient < NodeClientBase
      
      def download_piece(piece_uid, piece_checksum)
        
        response = call(:get, Proto::Node::DOWNLOAD_PIECE_PATH, { :piece => { :uid => piece_uid, :checksum => piece_checksum } })
        data = response[:piece]
        bad_response unless data && data.is_a?(String)
        
        data
      end
      
    end
    
    ##########
    
  end
end
