require 'socketry/config/server_client_base'

module Socketry
  module Config
    
    ##########
    
    class TrackerClientConfig < ServerClientBaseConfig
    end
    
    ##########

    def self.tracker_client
      @@tracker_client_config ||= TrackerClientConfig.load!
    end

    ##########
    
  end
end
