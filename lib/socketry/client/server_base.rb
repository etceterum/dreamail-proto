require 'net/http'

require 'socketry/proto'
require 'socketry/config/server_client_base'
require 'socketry/config/node'
require 'socketry/config/user'
require 'socketry/encoder'
require 'socketry/client/base'

module Socketry
  module Client
    
    ##########
    
    class ServerClientBase < Base
      attr_reader :server_config, :node_config, :user_config
      
      def initialize(server_config, node_config, user_config)
        @server_config = server_config
        @node_config = node_config
        @user_config = user_config
      end
      
      def call(method, path, data)
        raise InternalError unless user_config.login && user_config.password
        data[Proto::User::LOGIN_FIELD] = user_config.login
        data[Proto::User::PASSWORD_FIELD] = user_config.password
        data[Proto::Node::UID_FIELD] = node_config.uid

        request = resolve_method(method).new(path)
        # request.basic_auth(user_config.login, user_config.password) if user_config.registered?
        # request[Proto::HTTP_SIGNATURE_FIELD] = Proto.signature
        
        cipher = OpenSSL::Cipher::Cipher.new(Proto::CIPHER_TYPE).encrypt
        cipher.key = cipher_key = cipher.random_key
        cipher.iv = cipher_iv = cipher.random_iv
        
        # FIXME
        d0 = Time.now
        head_data = [cipher_key, cipher_iv, Proto.signature]
        d1 = head_data
        head_data = Encoder.encode(head_data)
        d2 = head_data
        head_data = server_config.public_key.public_encrypt(head_data)
        d3 = head_data
        body_data = Encoder.encode(data)
        d4 = head_data
        
        body_data = cipher.update(body_data)
        body_data << cipher.final
        
        request.form_data = { 
          Proto::HEAD_FIELD => head_data,
          Proto::BODY_FIELD => body_data
        }
        
        response_data = nil
        begin
          
          response = server.request(request)
          
          case response.code
          when '304' then raise Unchanged.new
          when '400' then raise BadRequest.new
          when '401' then raise BadIdentity.new
          else
            response.value
          end
          response_data = response.body
        rescue ProtoError => e
          # FIXME
          puts("="*100)
          puts "e. #{e}"
          puts "0. #{d0.inspect}"
          puts "1. #{d1.inspect}"
          puts "2. #{d2.inspect}"
          puts "3. #{d3.inspect}"
          puts "4. #{d4.inspect}"
          raise
        rescue EOFError, Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::ECONNABORTED, Errno::EPIPE, Errno::EINVAL, Errno::EBADF => e
          raise ConnectionFailure.new(e)
        rescue Object => e
          # raise ProtoError.new("#{self.class.name}: #{method.to_s.capitalize} call to \"#{path}\" failed (#{e})")
          puts "ServerBase: Exception: #{e}"
          raise
        end
        
        decipher = OpenSSL::Cipher::Cipher.new(Proto::CIPHER_TYPE).decrypt
        decipher.key = cipher_key
        decipher.iv = cipher_iv
        
        begin
          response_data = decipher.update(response_data)
          response_data << decipher.final
          # p response_data
          response_data = Encoder.decode(response_data)
        rescue Object => e
          bad_response
        end
        
        # p response_data
        bad_request unless response_data.is_a?(Hash)
        bad_request unless response_data[Proto::NOW_FIELD] && response_data[Proto::NOW_FIELD].is_a?(Time)
        response_data
      end

      protected
      
      def ensure_user_registered
        raise InternalError.new("User is not registered") unless user_config.registered?
      end
      
      def ensure_node_registered
        raise InternalError.new("Node is not registered") unless node_config.registered?
      end
      
      def ensure_user_and_node_registered
        ensure_user_registered
        ensure_node_registered
      end
      
      private
      
      def server
        @server ||= Net::HTTP.new(server_config.host, server_config.port)
      end
      
      def resolve_method(method)
        case method
        when :get     then Net::HTTP::Get
        when :post    then Net::HTTP::Post
        when :put     then Net::HTTP::Put
        when :delete  then Net::HTTP::Delete
        when :head    then Net::HTTP::Head
        else
          raise InternalError("#{self.class.name}: Invalid method \"#{method}\"")
        end
      end
      
      def bad_response
        raise BadResponse.new
      end
      
    end
    
    ##########
    
  end
end
