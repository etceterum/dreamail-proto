require 'socketry/config/base'

module Socketry
  module Config
    
    ##########
    
    class PingConfig < Base
      attr_accessor :timestamp
      
      def initialize(timestamp)
        @timestamp = timestamp
      end
      
      def dump
        { :timestamp => @timestamp }
      end
      
      def self.parse(hash)
        self.new(hash[:timestamp])
      end
      
    end
    
    ##########

    def self.ping
      @@ping_config ||= PingConfig.load!
    end

    ##########
    
  end
end
