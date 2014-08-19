require 'socketry/error'

require 'socketry/service/base'

module Socketry
  module Service
    
    class PassiveService < Base
      
      protected

      # tell the service there is something for it to process
      def kick
        passive_mutex.synchronize do
          passive_cond.signal
        end
      end
      
      protected
      
      def step
        process
        
        passive_mutex.synchronize do
          passive_cond.wait(passive_mutex)
        end
      end
      
      # to be overridden by implementations
      def process
        raise NotImplemented.new
      end
      
      private
      
      def passive_mutex
        @passive_mutex ||= Mutex.new
      end
      
      def passive_cond
        @passive_cond ||= ConditionVariable.new
      end
      
    end
    
  end
end
