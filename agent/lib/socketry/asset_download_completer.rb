require 'socketry/error'

require 'socketry/compiler'

require 'socketry/head_asset_processor'
require 'socketry/body_asset_processor'
require 'socketry/attachment_asset_processor'

module Socketry
  class AssetDownloadCompleter
    
    def complete_asset_download(asset_download)
      # check integrity of the asset
      asset = asset_download.asset
      Compiler.new.check_file_integrity(asset.path, asset.size, asset.checksum)
      
      # process asset in a type-specific way
      processor(asset_download.type).process_asset(asset)
      asset_download.destroy
    end
    
    private
    
    def processor(type)
      result = case type
      when :head then HeadAssetProcessor.new
      when :body then BodyAssetProcessor.new
      when :attachment then AttachmentAssetProcessor.new
      else
        raise InternalError.new("Unknown asset download type \"#{type}\"")
      end
    end
    
  end
end