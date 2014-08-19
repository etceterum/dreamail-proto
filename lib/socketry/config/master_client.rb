require 'socketry/config/server_client_base'

module Socketry
  module Config
    
    ##########
    
    class MasterClientConfig < ServerClientBaseConfig
    end
    
    ##########

    def self.master_client
      @@master_client_config ||= MasterClientConfig.load!
    end

    ##########
    
  end
end
