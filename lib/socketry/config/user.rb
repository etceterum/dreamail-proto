require 'socketry/config/base'

module Socketry
  module Config
    
    ##########
    
    class UserConfig < Base
      attr_accessor :login, :password
      
      def initialize(login, password)
        @login = login
        @password = password
      end
      
      def registered?
        !login.nil?
      end
      
      def dump
        { :login => @login, :password => @password }
      end
      
      def self.parse(hash)
        self.new(hash[:login], hash[:password])
      end
      
    end
    
    ##########

    def self.user
      @@user_config ||= UserConfig.load
    end

    ##########
    
  end
end
