require 'openssl'

require 'socketry/config/base'

module Socketry
  module Config
    
    ##########
    
    class ServerClientBaseConfig < Base
      attr_accessor :host, :port, :security
      attr_accessor :public_key
      
      def initialize(host, port, security)
        @host = host
        @port = port
        @security = security
        init_security!
      end
      
      def dump
        { :host => @host, :port => @port, :security => @security }
      end
      
      def self.parse(hash)
        self.new(hash[:host], hash[:port], hash[:security])
      end
      
      def self.private?
        false
      end
      
      def self.security_dirname
        File.join(dirname, type.underscore)
      end
      
      private
      
      def init_security!
        raise ConfigError("No security data in #{type} configuration") unless security && security[:public_key]
        @public_key = self.class.load_public_key!(security[:public_key])
      end
      
      def self.load_public_key!(relative_path)
        OpenSSL::PKey::RSA.new(load_plain(File.join(security_dirname, relative_path), true))
      end
      
    end
    
    ##########
    
  end
end
