require 'thread'

require 'socketry/dbhack'
require 'socketry/service/group'
require 'socketry/client/download'

module Socketry
  module Service
    
    ##########

    class DownloadWorker < Base
      ##########

      def initialize(queue)
        @queue = queue
      end

      ##########
      protected
      
      def step
        download_attempt = @queue.pop
        
        service_exclusive do
          process(download_attempt)
        end
        
        sleep 0.1
      end
      
      ##########
      private
      
      def process(download_attempt)
        download = download_attempt.download
        piece = download.piece
        asset = piece.asset
        source = download_attempt.source
        node = source.node
        begin
          logger.info "DownloadWorker: Downloading #{asset.uid}:#{piece.position} from #{node.uid} (#{piece.transit_size}B)"
          download_client = Client::DownloadClient.new(node.host, node.port, node.uid, node.public_key)
          data = download_client.download_piece(piece.uid, piece.transit_checksum)
          download.complete!(data)
        rescue ProtoError => e
          # connection problem: mark the node as unavailable
          logger.error "DownloadWorker: Connection to node #{node.uid} failed: #{e}"
          node.touch(:offline_at)
        rescue Object => e
          # connected to node, but couldn't download the piece, mark source as failed
          # otherwise, don't do anything - will retry later
          logger.error "DownloadWorker: Piece #{piece.uid} download failed from node #{node.uid}: #{e}"
          logger.error e.backtrace.join("\n")
          source.touch(:failed_at)
        ensure
          download_attempt.destroy
        end
      ensure
        DB.release_connection
      end

      ##########
    end

    ##########
    
    class DownloadService < ServiceGroup
      ##########
      
      WORKER_COUNT = 3
      
      ##########
      
      def initialize
        super
        @queue = SizedQueue.new(WORKER_COUNT)
        WORKER_COUNT.times do
          self << DownloadWorker.new(@queue)
        end
      end
      
      ##########

      def schedule(download_attempt)
        @queue.push(download_attempt)
      end

      ##########
    end
    
    ##########

    def self.download
      @@download ||= DownloadService.new
    end

    ##########
    
  end
end