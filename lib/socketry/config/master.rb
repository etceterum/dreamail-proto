require 'openssl'

require 'socketry/config/base'

module Socketry
  module Config
    
    ##########
    
    class MasterConfig < Base
      attr_accessor :port, :security
      attr_accessor :private_key
      
      def initialize(port, security)
        @port = port
        @security = security
        init_security!
      end
      
      def dump
        { :port => @port, :security => @security }
      end
      
      def self.parse(hash)
        self.new(hash[:port], hash[:security])
      end
      
      def self.private?
        false
      end
      
      def self.security_dirname
        File.join(dirname, type.underscore)
      end
      
      private
      
      def init_security!
        raise ConfigError.new("No security data in #{self.class.type} configuration") unless security && security[:passphrase] && security[:private_key]
        @passphrase = self.class.load_plain!(security[:passphrase])
        @private_key = OpenSSL::PKey::RSA.new(self.class.load_plain!(security[:private_key]), @passphrase)
      end
      
      def self.load_plain!(relative_path)
        load_plain(File.join(security_dirname, relative_path), true)
      end
      
    end
    
    ##########

    def self.master
      @@master_config ||= MasterConfig.load!
    end

    ##########
    
  end
end
