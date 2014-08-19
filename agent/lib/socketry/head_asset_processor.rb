require 'socketry/error'
require 'socketry/encoder'
require 'socketry/compiler'
require 'socketry/config/base'

module Socketry
  class HeadAssetProcessor
    
    def process_asset(asset)
      message = InMessage.find_by_head_asset_id(asset.id)
      
      raise InternalError.new("Cannot locate in-message for asset #{asset.id} as head asset") unless message
      raise InternalError.new("Message #{message.id} with #{asset.id} head asset already has body asset") if message.has_body_asset?
      
      data = Encoder.decode(File.read(asset.path))[:body][:asset]
      path = File.join(Socketry::Config::PRIVATE_LOCAL_ASSETS_ROOT, "i_#{message.format_id}.body")
      
      body_asset = nil
      InMessage.transaction do
        body_asset = message.create_body_asset(
          :uid => data[:uid],
          :path => path,
          :size => data[:size],
          :active => true,
          :hex_checksum => data[:checksum],
          :hex_cipher_key => message.hex_cipher_key,
          :hex_cipher_iv => message.hex_cipher_iv
        )
        
        body_download = body_asset.build_download
        body_download.type = :body
        body_download.save!
        
        data[:pieces].each_with_index do |p, i|
          piece = body_asset.pieces.create(
            :uid => p[:uid],
            :position => i,
            :offset => p[:offset],
            :size => p[:size],
            :transit_size => p[:transit][:size],
            :hex_transit_checksum => p[:transit][:checksum],
            :compressed => p[:transit][:compressed]
            )
          body_download.piece_downloads.create(:piece => piece)
        end

        # to associate with body asset
        message.save!

        Compiler.new.create_placeholder_file(body_asset.path, body_asset.size)
      end
      
      puts "Created body asset #{body_asset.uid} for in-message #{message.uid}"
      
    end
    
  end
end
