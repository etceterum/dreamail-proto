require 'socketry/service/base'

module Socketry
  module Service
    
    ##########

    class SimpleDownloadService < Base
      ##########

      IDLE_SLEEP_INTERVAL = 2
      BUSY_SLEEP_INTERVAL = 0.001

      ##########
      protected
      
      def step
        logger.info "SimpleDownload step"
        sleep_interval = IDLE_SLEEP_INTERVAL

        service_exclusive do
          sleep_interval = BUSY_SLEEP_INTERVAL if process
        end
        
        logger.debug "SimpleDownload sleep (#{sleep_interval})"
        sleep sleep_interval
      rescue StopService
        raise
      rescue Exception => e
        logger.info "SimpleDownload: #{e}"
        sleep 0.1
      rescue Object => e
        puts e.backtrace.join("\n")
        raise
      end
      
      ##########
      private
      
      def process
        # destroy attempt downloads if any are left from previous times, and weren't
        # destroyed because of an exception
        PieceDownloadAttempt.destroy_all
        
        # get piece download sources to process one by one, until we run out
        if piece_download_source = PieceDownloadSource.next_to_attempt
          logger.info ">> #{piece_download_source.download.piece.asset_id}"
          
          # p piece_download_source
          download = piece_download_source.download
          download_attempt = download.create_attempt(:source => piece_download_source)
          
          attempt_download(download_attempt)
          true
        else
          false
        end
      ensure
        DB.release_connection
      end
      
      ##########
      private

      def attempt_download(download_attempt)
        download = download_attempt.download
        piece = download.piece
        asset = piece.asset
        source = download_attempt.source
        node = source.node
        
        begin
          logger.info "SimpleDownload: Downloading #{asset.uid}:#{piece.position} from #{node.uid} (#{piece.transit_size}B)"
          download_client = Client::DownloadClient.new(node.host, node.port, node.uid, node.public_key)
          data = download_client.download_piece(piece.uid, piece.transit_checksum)
          download.complete!(data)
        rescue ConnectionFailure => e
          # connection problem: mark the node as unavailable
          logger.error "DownloadWorker: Connection to node #{node.uid} failed: #{e}"
          node.touch(:offline_at)
        rescue SocketryError => e
          # connected to node, but couldn't download the piece, mark source as failed
          # otherwise, don't do anything - will retry later
          logger.error "SimpleDownload: Piece #{piece.uid} download failed from node #{node.uid}: #{e}"
          source.touch(:failed_at)
        rescue Object => e
          logger.error "SimpleDownload: exception: #{e}"
          logger.error e.backtrace.join("\n")
          raise
        end
        
      ensure
        download_attempt.destroy
      end

      ##########
    end
    
    ##########
    
    def self.simple_download
      @@simple_download ||= SimpleDownloadService.new
    end
    
    ##########

  end
end
