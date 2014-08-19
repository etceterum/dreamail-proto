require 'dispatcher'
require 'mongrel'
require 'mongrel/rails'

require 'socketry/service/base'

require 'socketry/config/node'

module Socketry
  module Service
    
    ##########
    
    class WebServerService < Base
      
      def initialize(port, host = nil)
        @port = port
        @host = host || 'localhost'
        
        @mongrel = Mongrel::HttpServer.new(@host, @port)
        @mongrel.register('/', Mongrel::Rails::RailsHandler.new('public', {}))
      end
      
      def run
        logger.info "Starting #{self.class} service at #{@host}:#{@port}"
        @mongrel.run
      end
      
      public
      
      def stop(synchronous = false)
        logger.info "Stopping #{self.class} service"
        @mongrel.stop(synchronous)
      end
      
    end

    ##########

    def self.web_server
      @@web_server ||= WebServerService.new(Config.node.port, Config.node.host)
    end

    ##########
    
  end
end
