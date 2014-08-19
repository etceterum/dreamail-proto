require 'socketry/service/base'
require 'socketry/pinger'

module Socketry
  module Service
    
    ##########
    
    class PingService < Base
      INTERVAL = 5
      
      def initialize
        @pinger = Pinger.new
        @pinger.logger = logger
      end
      
      protected
      
      def step
        begin
          service_exclusive do
            @pinger.ping
          end
        rescue StopService
          raise
        rescue Object => e
          logger.error "Ping: #{e}"
        ensure
          # release thread's DB connection
          DB.release_connection
        end
        
        logger.debug "PingService: sleep(#{INTERVAL})"
        sleep INTERVAL
      end
      
    end

    ##########
    
    def self.ping
      @@ping ||= PingService.new
    end
    
    ##########
    
  end
end
