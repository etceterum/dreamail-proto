require 'thread'

require 'socketry/error'
require 'socketry/logger'

module Socketry
  module Service
    
    class StopService < Exception; end
    
    class Base
      attr_reader :thread

      def self.logger
        @@logger ||= Socketry.logger
      end
      
      def self.logger=(logger)
        @@logger = logger
      end
      
      def logger
        @logger ||= self.class.logger
      end
      
      attr_writer :logger
      
      def run
        before_run
        logger.info "Starting #{self.class} service"
        @thread = Thread.new do
          begin
            prologue
            body
          rescue StopService
            logger.info "StopService #{self.class} service"
          end
        end
        
        @thread
      end
      
      def stop(synchronous = false)
        before_stop(synchronous)
        
        @thread.raise(StopService.new)
        
        if synchronous
          sleep(0.5) while @thread.alive?
        end
      end
      
      def join
        run.join
      end
      
      protected
      
      # to be overridden by implementations as needed
      def before_run
      end
      
      # to be overridden by implementations as needed
      def prologue
      end
      
      # to be overridden by implementations as needed
      def before_stop(synchronous)
      end
      
      # may be overridden by implementations as needed
      def body
        begin
          loop do
            step
          end
        rescue StopService
          raise
        rescue Exception => e
          STDERR.puts "#{Time.now}: #{self.class} exception in body: #{e}"
          # STDERR.puts e.backtrace.join("\n")
        rescue Object => e
          STDERR.puts "#{Time.now}: #{self.class} in body: #{e}"
          raise
        end
      end
      
      # must be overridden unless body is overridden and doesn't use step
      def step
        raise NotImplemented.new
      end
      
      protected
      
      def service_exclusive(&block)
        common_mutex.synchronize do
          block.call
        end
      end
      
      private
      
      def common_mutex
        @@common_mutex ||= Mutex.new
      end
      
    end
    
  end
end
