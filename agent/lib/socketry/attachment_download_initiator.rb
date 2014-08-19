require 'fileutils'

require 'socketry/config/base'
require 'socketry/encoder'
require 'socketry/compiler'

module Socketry

  ##########

  class AttachmentDownloadInitiator
    
    ##########

    def initiate_attachment_download(attachment)

      message = attachment.message
      message_body_asset = message.body_asset
      message_body_asset_data = Encoder.decode(File.read(message_body_asset.path))

      for att_data in message_body_asset_data[:attachments]
        next unless att_data[:path] == attachment.relative_path
        data = att_data[:asset]

        local_path_prefix = File.join(Config::PRIVATE_LOCAL_ASSETS_ROOT, "incoming", message.format_id)
        path = File.join(local_path_prefix, att_data[:path])
        dir = File.dirname(path)
        FileUtils.mkdir_p(dir)

        InAttachment.transaction do
          asset = attachment.create_asset(
            :uid => data[:uid],
            :path => path,
            :size => data[:size],
            :active => true,
            :hex_checksum => data[:checksum],
            :hex_cipher_key => message.hex_cipher_key,
            :hex_cipher_iv => message.hex_cipher_iv
          )
          attachment.save!

          asset_download = asset.build_download
          asset_download.type = :attachment
          asset_download.save!

          data[:pieces].each_with_index do |p, i|
            piece = asset.pieces.create(
              :uid => p[:uid],
              :position => i,
              :offset => p[:offset],
              :size => p[:size],
              :transit_size => p[:transit][:size],
              :hex_transit_checksum => p[:transit][:checksum],
              :compressed => p[:transit][:compressed]
              )
            asset_download.piece_downloads.create(:piece => piece)
          end

          Compiler.new.create_placeholder_file(asset.path, asset.size)

        end
      end
    end
    
    ##########
  end

  ##########

  def self.attachment_download_initiator
    @@attachment_download_initiator ||= AttachmentDownloadInitiator.new
  end

  ##########
end
