class OutMessage < ActiveRecord::Base
  ##########

  STATUSES = [
    :draft,
    :unsent,
    :sent
  ]

  ##########

  named_scope :drafts,  :conditions => { :status_code => STATUSES.index(:draft) }
  named_scope :unsent,  :conditions => { :status_code => STATUSES.index(:unsent) }
  named_scope :sent,    :conditions => { :status_code => STATUSES.index(:sent) }
  named_scope :ordered, :order => 'out_messages.id asc'

  ##########

  def status
    STATUSES[status_code]
  end
  
  def status=(s)
    code = STATUSES.index(s)
    raise "Bad status" if code.nil?
    self.status_code = code
  end
  
  def draft?
    status == :draft
  end

  def unsent?
    status == :unsent
  end
  
  ##########

  def sent?
    status == :sent
  end
  
  def send!
    raise Socketry::InternalError.new('Already sent') if sent?
    self.status = :sent
    save!
  end
  
  ##########

  def announced?
    !uid.nil?
  end
  
  def announce!(uid)
    raise Socketry::InternalError.new('Already announced') if announced?
    self.uid = uid
    save!
  end

  ##########

  def format_id
    '%08x' % id
  end

  ##########
  
  has_many    :recipients, :class_name => 'OutRecipient', :dependent => :destroy
  has_many    :contacts, :through => :recipients
  has_many    :attachments, :class_name => 'OutAttachment', :foreign_key => 'out_message_id', :dependent => :destroy
  belongs_to  :body_asset, :class_name => 'Asset', :foreign_key => 'body_asset_id', :dependent => :destroy
  belongs_to  :head_asset, :class_name => 'Asset', :foreign_key => 'head_asset_id', :dependent => :destroy
  
  has_many    :requests, :class_name => 'OutMessageRequest', :dependent => :destroy
  
  before_validation_on_create :generate_cipher_data
  
  validates_presence_of :hex_cipher_key
  validates_presence_of :hex_cipher_iv

  ##########

  accepts_nested_attributes_for :recipients, :allow_destroy => true
  accepts_nested_attributes_for :attachments, :allow_destroy => true

  ##########

  def has_recipients?
    !recipients.empty?
  end

  ##########
  
  def body_compiled?
    !body_asset.nil?
  end
  
  def body_announced?
    body_compiled? && body_asset.announced?
  end
  
  def body_metainfo
    data = {
      :subject => subject,
      :content => content,
      :attachments => []
    }
    attachments_data = data[:attachments]
    for attachment in attachments.ordered_by_relative_path
      attachments_data << attachment.metainfo
    end
    data
  end
  
  def encode_body_metainfo
    Socketry::Encoder.encode(body_metainfo)
  end
  
  ##########

  def head_compiled?
    !head_asset.nil?
  end
  
  def head_announced?
    head_compiled? && head_asset.announced?
  end
  
  def head_metainfo
    raise Socketry::InternalError.new unless body_announced?
    data = {
      :body => { 
        :asset => body_asset.metainfo 
      }
    }
    
    data
  end
  
  def encode_head_metainfo
    Socketry::Encoder.encode(head_metainfo)
  end
  
  ##########

  def cipher_key
    Socketry::Encoder.hex_to_bin(hex_cipher_key)
  end
  
  def cipher_key=(bin_cipher_key)
    self.hex_cipher_key = Socketry::Encoder.bin_to_hex(bin_cipher_key)
  end

  def cipher_iv
    Socketry::Encoder.hex_to_bin(hex_cipher_iv)
  end
  
  def cipher_iv=(bin_cipher_iv)
    self.hex_cipher_iv = Socketry::Encoder.bin_to_hex(bin_cipher_iv)
  end

  ##########

  private
  
  def generate_cipher_data
    cipher = OpenSSL::Cipher::Cipher.new(Socketry::Proto::CIPHER_TYPE).encrypt
    self.cipher_key = cipher.random_key
    self.cipher_iv = cipher.random_iv
  end

  ##########
end
