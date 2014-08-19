require 'socketry/client/server_base'

module Socketry
  module Client
    
    ##########
    
    class TrackerClient < ServerClientBase

      def announce_asset(pieces)
        ensure_user_and_node_registered

        response = call(:post, Proto::Tracker::ANNOUNCE_ASSET_PATH, { Proto::Tracker::PIECES_FIELD => pieces })
        # p response
        asset_uid = response[Proto::Tracker::ASSET_FIELD]
        bad_response unless asset_uid
        piece_uids = response[Proto::Tracker::PIECES_FIELD]
        bad_response unless piece_uids && piece_uids.is_a?(Array) && piece_uids.size == pieces.size
        [asset_uid, piece_uids]
      end
      
      def activate_assets(asset_uids)
        ensure_user_and_node_registered

        response = call(:put, Proto::Tracker::ACTIVATE_ASSETS_PATH, { Proto::Tracker::ASSETS_FIELD => asset_uids })
        # p response
        true
      end
      
      def track_asset(asset_uid, piece_mask)
        ensure_user_and_node_registered
        
        response = call(:put, Proto::Tracker::TRACK_ASSET_PATH, { Proto::Tracker::ASSET_FIELD => asset_uid, Proto::Tracker::PIECES_FIELD => piece_mask })
        # p response
        nodes = response[Proto::Tracker::NODES_FIELD]
        bad_response unless nodes && nodes.is_a?(Array)
        nodes
      end
      
    end
    
    ##########

    def self.tracker
      @@tracker_client ||= TrackerClient.new(Config.tracker_client, Config.node, Config.user)
    end

    ##########
    
  end
end
