require 'logger'
require 'openssl'

require 'socketry/encoder'
require 'socketry/error'

module Socketry
  
  class PingerError < SocketryError
  end
  
  class Pinger
    GRACE = 60.seconds
    
    @@logger = Logger.new(STDERR)
    cattr_accessor  :logger
    
    def logger
      @logger ||= @@logger
    end

    attr_writer     :logger
    
    def ping
      logger.info "Ping"
      
      message_responses = format_message_responses
      message_receipts = format_message_receipts
      
      begin
        since = Socketry::Config.ping.timestamp
        since -= GRACE if since && since.is_a?(Time)
        logger.debug "Contacting Master (since: #{since})"
        response = Socketry::Client.master.ping(since, message_responses, message_receipts)
      rescue Object => e
        # puts e.backtrace.join("\n")
        error "Request to master failed: #{e}"
      end
      
      logger.debug "Processing Master response"
      process_response(response)
      confirm_message_receipts(message_receipts)
      
      logger.debug "Ping end"
      true
    end
    
    private
    
    def format_message_responses
      message_requests = OutMessageRequest.all
      message_responses = []
      return message_responses if message_requests.empty?
      
      logger.info "Formatting #{message_requests.size} message responses"
      
      for message_request in message_requests
        message_responses << format_message_response(message_request)
      end
      OutMessageRequest.destroy_all
      message_responses
    end
    
    def format_message_response(message_request)
      message = message_request.message
      
      auth = [message.cipher_key, message.cipher_iv]
      auth = Encoder.encode(auth)
      public_key = OpenSSL::PKey::RSA.new(message_request.node_public_key)
      auth = public_key.public_encrypt(auth)
      auth = Encoder.bin_to_hex(auth)
      
      data = message.head_asset.metainfo
      data = Encoder.encode(data)
      cipher = OpenSSL::Cipher::Cipher.new(Proto::CIPHER_TYPE).encrypt
      cipher.key = message.cipher_key
      cipher.iv = message.cipher_iv
      data = cipher.update(data)
      data << cipher.final
      data = Encoder.bin_to_hex(data)
      
      message_response = {
        :announcement => message.uid,
        :receiver => message_request.node_uid,
        :auth => auth,
        :data => data
      }
    end
    
    def format_message_receipts
      unconfirmed_messages = InMessage.not_confirmed
      message_receipts = []
      return message_receipts if unconfirmed_messages.empty?
      
      logger.info "Formatting #{unconfirmed_messages.size} message receipts"
      for unconfirmed_message in unconfirmed_messages
        message_receipts << format_message_receipt(unconfirmed_message)
      end
      
      message_receipts
    end
    
    def format_message_receipt(unconfirmed_message)
      unconfirmed_message.uid
    end
    
    def process_response(response)
      process_contacts(response[:added_contacts], [])
      process_message_requests(response[:message_requests])
      process_messages(response[:messages])
      process_timestamp(response[:now])
    end
    
    def confirm_message_receipts(message_receipts)
      for message_receipt in message_receipts
        message = InMessage.find_by_uid(message_receipt)
        message.touch(:confirmed_at) if message
      end
    end
    
    # FIXME: this currently is a stub
    def process_contacts(added_contact_logins, removed_contact_logins)
      logger.debug "Updating Contacts"
      
      old_contacts = Contact.all.collect { |c| c }
      new_contacts = []
      for contact_login in added_contact_logins do
        old_contact = old_contacts.find { |c| c.login == contact_login }
        if old_contact
          old_contacts.delete old_contact
          new_contacts << old_contact
          unless old_contact.active?
            old_contact.active = true
            logger.info "  A #{contact_login}"
          end
        else
          new_contacts << Contact.new(:login => contact_login, :active => true)
          logger.info "  + #{contact_login}"
        end
      end

      for old_contact in old_contacts
        logger.info "  - #{contact_login}"
        old_contact.active = false
        new_contacts << old_contact
      end

      Contact.transaction do
        for contact in new_contacts
          contact.save!
        end
      end
    end
    
    def process_message_requests(message_requests)
      return if message_requests.empty?
      
      logger.info "Processing #{message_requests.size} message requests"
      
      for message_request in message_requests
        process_message_request(message_request)
      end
    end
    
    def process_message_request(message_request)
      message_uid = message_request[:announcement]
      receiver = message_request[:receiver]
      contact_login = receiver[:user]
      contact_node_uid = receiver[:node][:uid]
      contact_node_public_key = receiver[:node][:public_key]
      
      # check message uid
      message = OutMessage.find_by_uid(message_uid)
      unless message
        logger.error "Invalid message UID \"#{message_uid}\", skipping"
        return
      end

      # check that the contact_login belongs to an active contact
      contact = Contact.active.find_by_login(contact_login)
      unless contact
        logger.warn "Contact \"#{contact_login}\" is not an active contact, skipping"
        return
      end
      
      OutMessageRequest.create(:message => message, :contact => contact, :node_uid => contact_node_uid, :node_public_key => contact_node_public_key)
    end
    
    def process_messages(messages)
      return if messages.empty?
      
      logger.info "Processing #{messages.size} incoming messages"
      
      for message in messages
        process_message(message)
      end
    end
    
    def process_message(message)
      
      uid = message[:uid]
      
      # see if already have a message by this uid
      if existing_message = InMessage.find_by_uid(uid)
        # reset the confirmed_at field so we confirm it again
        existing_message.confirmed_at = nil
        existing_message.save!
        return
      end
      
      sent_at = message[:sent_at]
      contact_login = message[:from]
      auth = message[:auth]
      data = message[:data]
      
      # decode auth
      auth = Encoder.hex_to_bin(auth)
      auth = Config.node.private_key.private_decrypt(auth)
      auth = Encoder.decode(auth)
      
      cipher_key = auth.shift
      cipher_iv = auth.shift
      
      # decode data
      decipher = OpenSSL::Cipher::Cipher.new(Proto::CIPHER_TYPE).decrypt
      decipher.key = cipher_key
      decipher.iv = cipher_iv
      data = Encoder.hex_to_bin(data)
      data = decipher.update(data)
      data << decipher.final
      data = Encoder.decode(data)
      
      # find or create(?) contact
      contact = Contact.find_by_login(contact_login)
      
      InMessage.transaction do
        # maybe we shouldn't create - and just ignore message?
        contact = Contact.create(:login => contact_login, :active => false) unless contact
      
        # create message
        message = InMessage.create(
          :uid => uid, 
          :sender => contact,
          :sent_at => sent_at, 
          :hex_cipher_key => Encoder.bin_to_hex(cipher_key),
          :hex_cipher_iv => Encoder.bin_to_hex(cipher_iv)
          )
      
        head_path = File.join(Socketry::Config::PRIVATE_LOCAL_ASSETS_ROOT, "i_#{message.format_id}.head")

        # create head asset
        head_asset = message.create_head_asset(
          :uid => data[:uid],
          :path => head_path,
          :size => data[:size],
          :active => true,
          :hex_checksum => data[:checksum],
          :hex_cipher_key => message.hex_cipher_key,
          :hex_cipher_iv => message.hex_cipher_iv
          )
        # resave the message again because otherwise head_asset_id won't be picked up (because of belongs_to?)
        message.save!
        
        head_download = head_asset.build_download
        head_download.type = :head
        head_download.save!
          
        data[:pieces].each_with_index do |p, i|
          piece = head_asset.pieces.create(
            :uid => p[:uid],
            :position => i,
            :offset => p[:offset],
            :size => p[:size],
            :transit_size => p[:transit][:size],
            :hex_transit_checksum => p[:transit][:checksum],
            :compressed => p[:transit][:compressed]
            )
          head_download.piece_downloads.create(:piece => piece)
        end
        
        Compiler.new.create_placeholder_file(head_asset.path, head_asset.size)
      end
      
    end
    
    def process_timestamp(timestamp)
      Socketry::Config.ping.timestamp = timestamp
      Socketry::Config.ping.save!
    end
    
    def error(message)
      raise PingerError.new(message)
    end
    
  end
  
end
