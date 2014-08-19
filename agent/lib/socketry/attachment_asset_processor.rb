require 'socketry/error'
require 'socketry/encoder'
require 'socketry/compiler'
require 'socketry/config/base'

module Socketry
  class AttachmentAssetProcessor
    
    def process_asset(asset)
      attachment = InAttachment.find_by_asset_id(asset.id)
      
      raise InternalError.new("Cannot locate in-attachment for asset #{asset.id}") unless attachment
      raise InternalError.new("Attachment #{attachment.id} with #{asset.id} as asset is already received") if attachment.here?

      InAttachment.transaction do
        # nothing to do really... maybe in future set received_at on the attachment
      end
      
      puts "Received attachment #{attachment.id} from asset #{asset.uid}"

    end
    
  end
end
