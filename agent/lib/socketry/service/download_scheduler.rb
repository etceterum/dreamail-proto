require 'socketry/dbhack'
require 'socketry/service/base'
require 'socketry/service/download'

module Socketry
  module Service
    ##########
    
    class DownloadSchedulerService < Base
      ##########

      IDLE_SLEEP_INTERVAL = 10

      ##########
      
      def initialize(download_service)
        @download_service = download_service
      end
      
      ##########
      protected
      
      def step
        logger.info "DownloadScheduler step"
        sleep_interval = IDLE_SLEEP_INTERVAL

        service_exclusive do
          process
        end
        
        logger.debug "DownloadScheduler sleep (#{sleep_interval})"
        sleep sleep_interval
      rescue Object => e
        puts e.backtrace.join("\n")
        raise
      end
      
      ##########
      private
      
      def process
        # TODO:
        # periodically reset statuses if piece download sources and nodes,
        # based on the time elapsed since the last failed attempt to contact them
          # Not needed because of the way PieceDownloadSource#next_to_attempt is implemented
        
        # get piece download sources to process one by one, until we run out
        while piece_download_source = PieceDownloadSource.next_to_attempt
          # if selected source is nil, happily sleep for (idle interval);
          # otherwise, create a new PieceDownloadAttempt object associated
          # with the selected source and feed it to DownloadService
          break unless piece_download_source
        
          # p piece_download_source
          download = piece_download_source.download
          download_attempt = download.create_attempt(:source => piece_download_source)
          begin
            @download_service.schedule(download_attempt)
          rescue Object => e
            download_attempt.destroy
            raise
          end
        end
      ensure
        DB.release_connection
      end
      
      ##########
    end
    
    ##########

    def self.download_scheduler
      @@download_scheduler ||= DownloadSchedulerService.new(download)
    end

    ##########
  end
end
