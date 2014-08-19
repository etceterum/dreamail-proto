require 'socketry/error'
require 'socketry/encoder'
require 'socketry/compiler'
require 'socketry/config/base'

module Socketry
  class BodyAssetProcessor
    
    def process_asset(asset)
      message = InMessage.find_by_body_asset_id(asset.id)
      
      raise InternalError.new("Cannot locate in-message for asset #{asset.id} as body asset") unless message
      raise InternalError.new("Message #{message.id} with #{asset.id} as body asset is already received") if message.received?
      
      data = Encoder.decode(File.read(asset.path))
      
      InMessage.transaction do
        message.subject = data[:subject]
        message.content = data[:content]
        
        for att_data in data[:attachments]
          
          attachment = message.attachments.create(
            :relative_path => att_data[:path],
            :size => att_data[:asset][:size]
          )
          
        end

        message.touch(:received_at)
      end
      
      puts "Populated message #{message.uid} from body asset #{asset.uid}"

    end
    
  end
end
