require 'socketry/config/base'

module Socketry
  module Config
    
    ##########
    
    class NodeConfig < Base
      attr_accessor :uid, :host, :port, :security
      attr_accessor :private_key, :public_key
      
      def initialize(uid, host, port, security)
        @uid = uid
        @host = host
        @port = port
        @security = security
        init_security!
      end
      
      def registered?
        !@uid.nil?
      end
      
      def dump
        { :uid => @uid, :host => @host, :port => @port, :security => @security }
      end
      
      def self.parse(hash)
        self.new(hash[:uid], hash[:host], hash[:port], hash[:security])
      end
      
      def self.security_dirname
        File.join(dirname, type.underscore)
      end

      private
      
      def init_security!
        raise ConfigError.new("No security data in #{self.class.type} configuration") unless security && security[:passphrase] && security[:private_key]
        @passphrase = self.class.load_plain!(security[:passphrase])
        @private_key = OpenSSL::PKey::RSA.new(self.class.load_plain!(security[:private_key]), @passphrase)
        @public_key = @private_key.public_key
      end
      
      def self.load_plain!(relative_path)
        load_plain(File.join(security_dirname, relative_path), true)
      end
      
    end
    
    ##########

    def self.node
      @@node_config ||= NodeConfig.load!
    end

    ##########
    
  end
end
