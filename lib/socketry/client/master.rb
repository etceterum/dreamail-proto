require 'socketry/client/server_base'

module Socketry
  module Client
    
    ##########
    
    class MasterClient < ServerClientBase

      def register_user
        ensure_node_not_registered

        call(:post, Proto::Master::NEW_USER_PATH, {})
        true
      end
      
      def register_node
        ensure_node_not_registered
        
        response = call(:post, Proto::Master::NEW_NODE_PATH, { Proto::Node::PUBLIC_KEY_FIELD => node_config.public_key.to_pem })
        # p response
        node_uid = response[Proto::Node::UID_FIELD]
        bad_response unless node_uid
        node_uid
      end
      
      def ping(since, message_responses, message_receipts)
        ensure_user_and_node_registered

        request = {
          Proto::Node::HOST_FIELD => node_config.host, 
          Proto::Node::PORT_FIELD => node_config.port,
          Proto::SINCE_FIELD => since,
          :message_responses => message_responses,
          :message_receipts => message_receipts
        }
        begin
          response = call(:put, Proto::Master::PING_PATH, request)
        rescue Object => e
          raise
          # FIXME
          # puts "PING FAILED: #{Time.now}"
          # p request
          # p e
          # puts e.backtrace.join("\n")
          # abort
        end
        # puts response.to_yaml
        result = {}
        contacts = response[Proto::Master::CONTACTS_FIELD]
        bad_response unless contacts && contacts.is_a?(Hash)
        added_contacts = contacts[Proto::ADD_FIELD]
        bad_response unless added_contacts && added_contacts.is_a?(Array)
        result[:added_contacts] = added_contacts
        result[:now] = response[Proto::NOW_FIELD]
        message_requests = response[:message_requests]
        bad_response unless message_requests && message_requests.is_a?(Array)
        result[:message_requests] = message_requests
        messages = response[:messages]
        bad_response unless messages && messages.is_a?(Array)
        result[:messages] = messages
        result
      end
      
      def announce_message(to_logins)
        ensure_user_and_node_registered

        response = call(:post, Proto::Master::ANNOUNCE_MESSAGE_PATH, { Proto::Message::TO_FIELD => to_logins })
        # p response
        errors = response[Proto::ERROR_FIELD]
        if errors
          bad_response unless errors.is_a?(Hash)
          bad_to_logins = response[Proto::Message::TO_FIELD]
          bad_response unless bad_to_logins && bad_to_logins.is_a?(Array) && !bad_to_logins.empty?
          return [false, bad_to_logins]
        end
        uid = response[Proto::Message::UID_FIELD]
        bad_response unless uid && uid.is_a?(String)
        [true, uid]
      end
      
      private
      
      def ensure_node_not_registered
        raise InternalError.new('Node is already registered') if node_config.registered?
      end
      
    end
    
    ##########

    def self.master
      @@master_client ||= MasterClient.new(Config.master_client, Config.node, Config.user)
    end

    ##########
    
  end
end
