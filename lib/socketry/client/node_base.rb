require 'net/http'

require 'socketry/proto'
require 'socketry/config/node'
require 'socketry/encoder'
require 'socketry/client/base'

module Socketry
  module Client
    
    ##########
    
    class NodeClientBase < Base
      attr_reader :host, :port, :uid, :public_key, :node_config
      
      def initialize(host, port, uid, public_key, node_config = Config.node)
        @host = host
        @port = port
        @uid = uid
        @public_key = public_key
        @node_config = node_config
      end
      
      def call(method, path, data)
        data[Proto::Node::OTHER_UID_FIELD] = uid
        data[Proto::Node::PUBLIC_KEY_FIELD] = {
          Proto::Node::MODULUS_FIELD => node_config.public_key.n.to_s(2),
          Proto::Node::EXPONENT_FIELD => node_config.public_key.e.to_i
        }
        data[Proto::Node::UID_FIELD] = node_config.uid

        request = resolve_method(method).new(path)
        
        cipher = OpenSSL::Cipher::Cipher.new(Proto::CIPHER_TYPE).encrypt
        cipher.key = cipher_key = cipher.random_key
        cipher.iv = cipher_iv = cipher.random_iv
        
        head_data = Encoder.encode([cipher_key, cipher_iv, Proto.signature])
        head_data = public_key.public_encrypt(head_data)
        body_data = Encoder.encode(data)
        body_data = cipher.update(body_data)
        body_data << cipher.final
        
        request.form_data = { 
          Proto::HEAD_FIELD => head_data,
          Proto::BODY_FIELD => body_data
        }
        
        response_data = nil
        begin
          response = remote.request(request)
          case response.code
          when '304' then raise Unchanged.new
          when '400' then raise BadRequest.new
          when '401' then raise BadIdentity.new
          when '404' then raise NotFound.new
          else
            response.value
          end
          response_data = response.body
        rescue ProtoError
          raise
        rescue EOFError, Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::ECONNABORTED, Errno::EPIPE, Errno::EINVAL, Errno::EBADF => e
          raise ConnectionFailure.new(e)
        rescue Object => e
          raise ProtoError.new("#{self.class.name}: #{method.to_s.capitalize} call to \"#{path}\" failed (#{e})")
        end
        
        # first Proto::RSA_KEY_SIZE_IN_BITS bits of response is the head
        response_head = response_data.slice!(0, Proto::RSA_KEY_SIZE_IN_BITS >> 3)
        bad_response unless response_head.length == (Proto::RSA_KEY_SIZE_IN_BITS >> 3)
        
        # using our private key to decrypt the head
        begin
          response_head = node_config.private_key.private_decrypt(response_head)
          response_head = Encoder.decode(response_head)
        rescue Object => e
          bad_response
        end
        
        bad_response unless response_head.is_a?(Array) && response_head.size == 3
        decipher_key = response_head.shift
        decipher_iv = response_head.shift
        proto = response_head.shift
        bad_response unless proto == Proto.signature
        
        decipher = OpenSSL::Cipher::Cipher.new(Proto::CIPHER_TYPE).decrypt
        bad_response unless decipher_key.is_a?(String) && decipher_key.length == decipher.key_len
        decipher.key = decipher_key
        bad_response unless decipher_iv.is_a?(String) && decipher_iv.length == decipher.block_size
        decipher.iv = decipher_iv
        
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

      private
      
      def remote
        @remote ||= Net::HTTP.new(host, port)
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
