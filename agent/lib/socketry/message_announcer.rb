require 'socketry/error'
require 'socketry/compiler'
require 'socketry/proto'

module Socketry
  
  ##########

  class MessageAnnouncerError < SocketryError
  end

  ##########

  class MessageAnnouncer
    ##########

    def initialize(message, stream = nil)
      @message = message
      raise InternalError.new("Invalid message state") unless @message.unsent?
      
      @compiler = Compiler.new(
        :max_piece_size => Proto::MAX_PIECE_SIZE,
        :hash_type => Proto::CHECKSUM_TYPE,
        :cipher_type => Proto::CIPHER_TYPE,
        :cipher_key => @message.cipher_key,
        :cipher_iv => @message.cipher_iv
        )
        
      @stream = stream
    end

    def announce
      compile_attachments
      announce_attachments_with_tracker
      compile_body
      announce_body_with_tracker
      compile_head
      announce_head_with_tracker
      announce_message
      activate_assets_with_tracker
      change_status
    end

    ##########
    
    private

    def compile_attachments
      attachments = @message.attachments.not_compiled

      for attachment in attachments

        stream_puts "  Compiling attachment #{attachment.relative_path}..."
        total = File.size(attachment.path)
        count = 0
        attachment.build_asset.compile(@compiler, attachment.path) do |progress|
          count += 1
          stream_print "    #{'%3d' % (progress*100.0/total)}% [#{progress} / #{total}]: #{count}\r"
          stream_flush
        end

        attachment.save!
      end
    end

    def compile_body
      return if @message.body_compiled?

      stream_puts "  Compiling message body..."
      data = @message.encode_body_metainfo

      total = data.length
      count = 0
      @message.build_body_asset.compile_from_string(@compiler, data, "o_#{@message.format_id}.body") do |progress|
        count += 1
        stream_print "    #{'%3d' % (progress*100.0/total)}% [#{progress} / #{total}]: #{count}\r"
        stream_flush
      end

      @message.save!
    end

    def compile_head
      return if @message.head_compiled?

      stream_puts "  Compiling message head..."
      data = @message.encode_head_metainfo
      total = data.length
      count = 0
      @message.build_head_asset.compile_from_string(@compiler, data, "#{@message.format_id}.head") do |progress|
        count += 1
        stream_print "    #{'%3d' % (progress*100.0/total)}% [#{progress} / #{total}]: #{count}\r"
        stream_flush
      end

      raise InternalError.new("Message head asset piece count is not 1") if @message.head_asset.pieces.size != 1

      @message.save!
    end

    def announce_attachments_with_tracker
      attachments = @message.attachments.not_announced

      for attachment in attachments
        stream_puts "  Announcing attachment #{attachment.relative_path} with the Tracker..."
        announce_asset_with_tracker(attachment.asset)
      end
    end

    def announce_body_with_tracker
      return if @message.body_announced?

      stream_puts "  Announcing message body with the Tracker..."
      announce_asset_with_tracker(@message.body_asset)
    end

    def announce_head_with_tracker
      return if @message.head_announced?

      stream_puts "  Announcing message head with the Tracker..."
      announce_asset_with_tracker(@message.head_asset)
    end

    def announce_asset_with_tracker(asset)
      pieces_data = []
      for piece in asset.pieces
        piece_data = [
          piece.transit_size,
          piece.transit_checksum
        ]
        pieces_data << piece_data
      end

      asset_uid, piece_uids = nil, nil
      begin
        asset_uid, piece_uids = Client.tracker.announce_asset(pieces_data)
      rescue Object => e
        error "Failed to publish asset with the Tracker: #{e}"
      end

      Asset.transaction do
        asset.uid = asset_uid
        asset.pieces.each_with_index do |piece, i|
          piece.uid = piece_uids[i]
          piece.save!
        end

        asset.save!
      end
    end

    def announce_message
      return if @message.announced?

      stream_puts "  Announcing message..."
      success, payload = nil, nil
      begin
        success, payload = Client.master.announce_message(@message.contacts.collect(&:login))
      rescue Object => e
        error "Failed to announce message: #{e}"
      end

      unless success
        bad_to_logins = payload
        error "Bad recipients: #{bad_to_logins.join(', ')}"
      end

      uid = payload
      @message.announce!(uid)
    end

    def activate_assets_with_tracker
      assets = []
      assets << @message.head_asset unless @message.head_asset.active?
      assets << @message.body_asset unless @message.body_asset.active?
      for attachment in @message.attachments
        assets << attachment.asset unless attachment.asset.active?
      end

      return if assets.empty?

      stream_puts "  Announcing message assets..."
      begin
        success = Client.tracker.activate_assets(assets.collect(&:uid))
      rescue Object => e
        error "Failed to activate message assets: #{e}"
      end

      Asset.transaction do
        for asset in assets
          asset.activate!
        end
      end
    end

    def change_status
      @message.send!
    end
    
    ##########

    private

    def stream_print(text)
      @stream.print text if @stream
    end

    def stream_puts(text)
      @stream.puts text if @stream
    end

    def stream_flush
      @stream.flush if @stream
    end
    
    def error(message)
      # stream_puts "Error: #{message}"
      raise MessageAnnouncerError.new(message)
    end

    ##########
  end
  
  ##########
end
