require 'thread'

require 'socketry/service/base'
require 'socketry/message_announcer'

module Socketry
  module Service
  
    ##########

    # FIXME:
    # Ruby 1.9.1 doesn't support timeout as 2nd parameter to ConditionVariable#wait,
    # therefore I cannot implement timed-out wait on a condition variable so that
    # the service becomes both periodically invoked and passive (kickable) - for
    # now just making it periodic;
    # TODO: consider switching back to Ruby 1.8? (does it support waited timeouts?)
    class MessageAnnouncementService < Base
      
      ##########

      INTERVAL = 5

      ##########

      # FIXME - see header
      # # tell the service there may be something for it to process
      # def kick
      #   mutex.synchronize do
      #     cond.signal
      #   end
      # end

      ##########
      
      protected
      
      def step
        logger.debug "Checking for outgoing messages to announce"
        
        begin
          messages = OutMessage.unsent.ordered
          for message in messages
            announce(message)
          end
        rescue Object => e
          logger.error e
        end
        
        # release thread's DB connection
        DB.release_connection

        # FIXME - see header
        # mutex.synchronize do
        #   cond.wait(mutex, INTERVAL)
        # end
        sleep INTERVAL
      end
      
      ##########

      private
      
      def announce(message)
        unless message.has_recipients?
          logger.error "#{message.id} - has no recipients: skipping"
          return
        end

        begin
          logger.info "Announcing outgoing message #{message.id} to #{message.contacts.collect(&:login).join(', ')}"
          MessageAnnouncer.new(message, $stdout).announce
          logger.debug "Finished announcing outgoing message #{message.id}"
        rescue Socketry::MessageAnnouncerError => e
          error(e)
        rescue Object => e
          error(e)
        end
      end
      
      def error(e)
        logger.error(e)
      end
    
      ##########

      # FIXME - see header
      # def mutex
      #   @mutex ||= Mutex.new
      # end
      # 
      # def cond
      #   @cond ||= ConditionVariable.new
      # end
      
      ##########

    end
  
    ##########
    
    def self.message_announcement
      @@message_announement ||= MessageAnnouncementService.new
    end
    
    ##########
  end
end
