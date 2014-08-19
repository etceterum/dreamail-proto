require 'socketry/service/base'

module Socketry
  module Service
    
    ##########

    class ServiceGroup < Base
      
      def initialize
        @services = []
        @threads = ThreadGroup.new
      end
      
      def <<(service)
        @services << service
      end
      
      protected
      
      def body
        for service in @services
          @threads.add(service.run)
          # give each service time to initialize in case they depend
          # on each other
          sleep 1
        end
        begin
          loop do
            sleep 1000
          end
        rescue StopService
          shutdown
        end
      end
      
      private
      
      def shutdown
        logger.info("Stopping service group")
        while @threads.list.size > 0
          for service in @services
            service.stop
          end
          sleep 1
        end
      end
      
    end

    ##########
    
    def self.all
      @@all ||= ServiceGroup.new
    end
    
    ##########
    
  end
end
