require 'openssl'

require 'socketry/dbhack'
require 'socketry/service/base'
require 'socketry/client/tracker'
require 'socketry/asset_download_completer'

module Socketry
  module Service
    
    ##########

    class TrackService < Base
      ##########

      IDLE_SLEEP_INTERVAL = 3

      ##########
      protected
      
      def before_run
        # cleanup from previous application runs
        PieceDownloadAttempt.destroy_all
        PieceDownloadSource.destroy_all
        Node.update_all(:offline_at => nil)
        AssetDownload.update_all(:track_at => nil)
        
        DB.release_connection
      end
      
      def step
        logger.info "Track step"
        sleep_interval = IDLE_SLEEP_INTERVAL
        
        service_exclusive do
          next_track_in = process
          sleep_interval = next_track_in if next_track_in < sleep_interval
        end
        
        sleep(sleep_interval) if sleep_interval > 0
      rescue StopService
        raise
      rescue Exception => e
        logger.info "Track: #{e}"
        sleep 0.1
      rescue Object => e
        puts e.backtrace.join("\n")
        raise
      end
      
      ##########
      private
      
      def process
        # find all new asset downloads - those that are not tracked
        asset_download_count = AssetDownload.count
        untracked_asset_downloads = AssetDownload.not_tracked
        for asset_download in untracked_asset_downloads
          asset_download.schedule!(Time.now + 2*rand(asset_download_count))
        end
        
        # find the earliest asset downloads due to track
        asset_download = AssetDownload.first_to_track
        if asset_download
          return 0 unless asset_download.track_at
          now = Time.now
          if asset_download.track_at <= now
            process_asset_download(asset_download)
            return 0
          end
          next_track_in = asset_download.track_at - now
        else
          IDLE_SLEEP_INTERVAL
        end
      rescue Exception => e
      rescue Object => e
        # puts e.backtrace.join("\n")
        raise
      ensure
        DB.release_connection
      end
      
      def process_asset_download(asset_download)
        asset = asset_download.asset
        logger.info "TrackService: Processing asset download: #{asset.uid}"
        
        # destroy all complete piece downloads
        asset_download.piece_downloads.complete.destroy_all
        
        # (and must reload because otherwise we'll get a frozen hash exception when we try to update asset_download)
        # Note: and simple call to asset_download.reload doesn't solve it.. go figure
        asset_download = AssetDownload.find(asset_download.id)
        
        track_asset_download(asset_download)

        asset_download.schedule! unless asset_download.complete?
      end
      
      def track_asset_download(asset_download)
        asset = asset_download.asset
        piece_mask = asset_download.piece_mask
        
        begin
          logger.info "TrackService: Tracking asset download #{asset.uid}"
          node_infos = Client.tracker.track_asset(asset.uid, piece_mask)
        rescue Object => e
          logger.error "TrackService: Tracker request failed for asset #{asset.uid}: #{e}"
          return
        end
        
        if piece_mask.empty?
          unless node_infos.empty?
            logger.error "TrackService: Weird... we have reported that we have all pieces and got non-empty node list back, ignoring"
          end
          # asset download is complete: call the completer and destroy asset download
          logger.info "TrackService: completing download of asset #{asset.uid}"
          AssetDownloadCompleter.new.complete_asset_download(asset_download)
          return
        end
        
        inverted_piece_mask = ~piece_mask
        
        for node_info in node_infos
        
          # process node identity
          uid = node_info[:uid]
          host = node_info[:host]
          port = node_info[:port]
        
          begin
            public_key_data = node_info[:public_key]
            modulus = OpenSSL::BN.new(public_key_data[:n], 2)
            exponent = OpenSSL::BN.new(public_key_data[:e].to_s)
            public_key = OpenSSL::PKey::RSA.new
            public_key.n = modulus
            public_key.e = exponent
          rescue Object => e
            logger.error "TrackService: Problem with public key reported for node #{uid} (#{e}), skipping the node"
            next
          end
        
          if node = Node.find_by_uid(uid)
          
            unless public_key.n == node.public_key.n && public_key.e == node.public_key.e
              logger.error "TrackService: Different public key reported for node #{uid}, ignoring new value"
            end

            # check if the node has moved to a different host/port 
            if node.port != port || node.host != host
              # node.lock!
              node.port = port
              node.host = host
              node.offline_at = nil
              node.save!
            end
          
          else
            # TODO: to prevent the node info cache from growing indefinitely, should implement
            # a purge mechanism here to push the 'worst' node away from the cache if the cache
            # size limit is reached
            node = Node.create(
              :uid => uid, 
              :public_modulus => modulus.to_s(2), 
              :public_exponent => exponent.to_i, 
              :host => host, 
              :port => port
              )
          end
        
          # process pieces possessed by the node
          node_piece_mask = node_info[:pieces]
          unless node_piece_mask.is_a?(BooleanVector)
            logger.error "TrackService: Piece mask reported for node #{uid} is invalid type, skipping"
            next
          end
          if node_piece_mask.empty?
            # node has all pieces
            node_piece_mask = BooleanVector.new(asset.pieces.count, true)
          else
            unless node_piece_mask.size == piece_mask.size
              logger.error "TrackService: Piece mask reported for node #{uid} is invalid size (#{node_piece_mask.size}), skipping"
              next
            end
          end

          node_wanted_piece_mask = inverted_piece_mask & node_piece_mask
          
          # now we have a mask of all pieces that the node has and we don't -
          # create missing piece download source records as needed...
          node_wanted_piece_positions = node_wanted_piece_mask.true_indices
          for node_wanted_piece_position in node_wanted_piece_positions
            
            piece = asset.pieces.find(:first, :conditions => { :position => node_wanted_piece_position })
            piece_download = piece.download
            piece_download.sources.find_or_create_by_node_id(node.id)
          end
        
        end
        
      end

      ##########
    end

    ##########

    def self.track
      @@track ||= TrackService.new
    end

    ##########
    
  end
end
