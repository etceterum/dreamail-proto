require 'openssl'

require 'socketry/service/base'
require 'socketry/client/tracker'

module Socketry
  module Service
    
    ##########

    class AssetInfo
      attr_accessor :next_track_at
      attr_reader   :logger, :download, :track_interval, :piece_infos
      
      def initialize(logger, asset_download, next_track_at, track_interval)
        @logger = logger
        @download = asset_download
        
        @next_track_at = next_track_at
        @track_interval = track_interval
        
        @piece_infos = {}
      end

      # reload the download record from the database;
      # purge any piece_infos that are related to the pieces we already have;
      # return true if the download is detected to be complete, false otherwise
      def update
        @download.reload
        piece_mask = @download.piece_mask
        # get positions of pieces we have
        piece_positions = piece_mask.true_indices
        # go over piece_infos structure and delete all entries with positions
        # in piece_positions
        for piece_position in piece_positions
          @piece_infos.delete(piece_position)
        end
        # detect if the download is complete and return the completion status as result
        complete = piece_mask.true?
      end
      
      def asset
        @download.asset
      end
      
      def uid
        asset.uid
      end
      
      def piece_mask
        @download.piece_mask
      end
      
      def touch
        @next_track_at = Time.now + @track_interval
      end
      
      def update_piece_infos(node_uid, node_piece_mask)
        asset_piece_mask = download.piece_mask
        
        # check and normalize node piece mask
        if node_piece_mask.empty?
          # node reports to have all pieces
          node_piece_mask = BooleanVector.new(asset_piece_mask.size, true)
        else
          if node_piece_mask.size != asset_piece_mask.size
            logger.error "Piece mask reported for node #{uid} is invalid size, skipping"
            return false
          end
        end
        
        # get mask for pieces that the node has and we don't
        piece_mask_diff = ~asset_piece_mask & node_piece_mask
        if piece_mask_diff.false?
          logger.error "Node #{uid} does not have any pieces that we don't have, skipping"
          return false
        end
        
        # get piece positions
        node_piece_positions = piece_mask_diff.true_indices
        
        # finally, update piece infos
        for node_piece_position in node_piece_positions
          return false unless update_or_create_piece_info(node_uid, node_piece_position)
        end
        
        true
      end
      
      private
      
      def update_or_create_piece_info(node_uid, node_piece_position)
        piece_info = @piece_infos[node_piece_position] ||= PieceInfo.new(self, node_piece_position)
        piece_info.update_with_node(node_uid)
      end
      
    end
    
    class PieceInfo
      attr_reader :asset_info, :download
      
      def initialize(asset_info, position)
        @asset_info = asset_info
        @position = position
        
        @node_statuses = {}
      end
      
      def update_with_node(node_uid)
        if node_status = @node_statuses[node_uid]
          # well, do nothing: we don't want to change the status because the
          # node is reported to have the piece again - status is only changed
          # when an attempt to download is made and it succeeds/fails
        else
          # TODO: in order to prevent this cache from growing indefinitely,
          # must implement some purging mechanism and push the worst-status
          # record away from cache if the size limit is reached
          node_status = @node_statuses[node_uid] = 0
        end
        true
      end
      
    end
    
    class NodeInfo
      attr_reader   :uid, :public_key
      attr_accessor :host, :port, :contacted_at, :status
      
      def initialize(uid, public_key, host, port)
        @uid = uid
        @public_key = public_key
        @host = host
        @port = port
        
        @contacted_at = nil
        @status = 0
        
        @asset_uids = {}
      end
      
      def reset_status
        @status = 0
      end
      
      def add_asset(asset_uid)
        @asset_uids[asset_uid] = true
      end
      
      # returns true if the @asset_uids hash becomes empty
      def remove_asset(asset_uid)
        @asset_uids.delete(asset_uid)
        @asset_uids.empty?
      end
      
    end

    ##########

    class TrackerPingService < Base
      ##########

      # TODO: in future, this value should either be stored in AssetDownload
      #       or obtained from the tracker in previous ping
      ASSET_PING_INTERVAL = 20
      
      IDLE_SLEEP_INTERVAL = 30

      ##########
      protected
      
      def prologue
        @asset_infos = []
        asset_downloads = AssetDownload.all.to_a
        ad_count = asset_downloads.size
        
        for asset_download in asset_downloads
          # randomize ping times a bit so not all asset requests are due at the same time
          @asset_infos << AssetInfo.new(logger, asset_download, Time.now + 2*rand(ad_count), ASSET_PING_INTERVAL)
        end
        
        @node_infos = {}
      end
      
      def step
        sleep_interval = IDLE_SLEEP_INTERVAL
        
        # find the earliest ping time among all assets, and corresponding asset UID/piece mask
        ai = earliest_asset_info_to_track
        if ai
          now = Time.now
          if ai.next_track_at <= now
            process_asset(ai)
            return
          end
          diff = ai.next_track_at - now
          sleep_interval = diff if diff < sleep_interval
        end
        
        sleep sleep_interval
      end
      
      ##########
      
      private
      
      def earliest_asset_info_to_track
        @asset_infos.sort! { |ai1, ai2| ai1.next_track_at <=> ai2.next_track_at }
        @asset_infos.first
      end

      private
      
      def process_asset(asset_info)
        # before tracking, update the asset download data stored in the asset_info
        # to remove piece_infos for already downloaded pieces;
        # if the download is detected to be complete, we still need to contact the tracker
        # one more time, but then we must remove the asset_info from the list of tracked assets
        # also, once the asset info is deleted, we should purge from node_infos all nodes
        # that are only related to that asset
        complete = asset_info.update
        
        begin
          track_asset(asset_info)
        rescue Object => e
          asset_info.touch
          raise
        end
        
        if complete
          asset_uid = asset_info.uid
          @asset_infos.delete(asset_info)
          cleanup_nodes(asset_uid)
        end
        
      end
      
      def track_asset(asset_info)
        piece_mask = asset_info.piece_mask
        piece_mask = BooleanVector.new(0) if piece_mask.true?
        
        begin
          uid = asset_info.uid
          logger.info "TrackerPing: #{uid}"
          nodes = Client.tracker.track_asset(uid, piece_mask)
        rescue Object => e
          logger.error "TrackerPing: Tracker request failed for asset #{uid}: #{e}"
          return
        end
        
        for node in nodes
          
          # process node identity
          uid = node[:uid]
          host = node[:host]
          port = node[:port]
          
          begin
            public_key_data = node[:public_key]
            modulus = OpenSSL::BN.new(public_key_data[:n], 2)
            exponent = OpenSSL::BN.new(public_key_data[:e].to_s)
            public_key = OpenSSL::PKey::RSA.new
            public_key.n = modulus
            public_key.e = exponent
          rescue Object => e
            logger.error "Problem with public key reported for node #{uid} (#{e}), skipping the node"
            next
          end
          
          if node_info = @node_infos[uid]
            
            unless public_key.n == node_info.public_key.n && public_key.e == node_info.public_key.e
              logger.error "Different public key reported for node #{uid}, ignoring new value"
            end

            # check if the node has moved to a different host/port 
            if node_info.port != port || node_info.host != host
              node_info.port = port
              node_info.host = host
              node_info.reset_status
            end
            
          else
            # TODO: to prevent the node info cache from growing indefinitely, should implement
            # a purge mechanism here to push the 'worst' node away from the cache if the cache
            # size limit is reached
            node_info = @node_infos[uid] = NodeInfo.new(uid, public_key, host, port)
          end
          
          node_info.add_asset(asset_info.uid)
          
          # process pieces possessed by the node
          node_piece_mask = node[:pieces]
          unless node_piece_mask.is_a?(BooleanVector)
            logger.error "Piece mask reported for node #{uid} is invalid type, skipping"
            next
          end
          
          # update asset info
          asset_info.update_piece_infos(uid, node_piece_mask)
          
        end
        
      end

      ##########

      def cleanup_nodes(asset_uid)
        node_uids_to_delete = []
        @node_infos.each do |node_uid, node_info|
          next unless node_info.remove_asset(asset_uid)
          node_uids_to_delete << node_uid
        end
        for node_uid in node_uids_to_delete
          @node_infos.delete(node_uid)
        end
      end

      ##########
    end

    ##########

    def self.tracker_ping
      @@tracker_ping ||= TrackerPingService.new
    end

    ##########
    
  end
end
