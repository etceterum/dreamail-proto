class InMessage < ActiveRecord::Base
  ##########

  named_scope :not_confirmed, :conditions => { :confirmed_at => nil }
  named_scope :received, :conditions => 'in_messages.received_at is not null'
  named_scope :unread, :conditions => { :read_at => nil }
  named_scope :with_id_greater_than, lambda { |id| { :conditions => ['in_messages.id > ?', id] } }
  named_scope :newest_first, :order => 'in_messages.id desc'

  ##########

  belongs_to  :sender, :class_name => 'Contact', :foreign_key => 'sender_id'
  
  belongs_to  :head_asset, :class_name => 'Asset', :foreign_key => 'head_asset_id'
  belongs_to  :body_asset, :class_name => 'Asset', :foreign_key => 'body_asset_id'
  
  has_many    :attachments, :class_name => 'InAttachment', :foreign_key => 'in_message_id'

  ##########
  
  def format_id
    '%08x' % id
  end

  ##########

  def has_body_asset?
    !body_asset.nil?
  end
  
  def received?
    !received_at.nil?
  end

  ##########

  def read?
    !read_at.nil?
  end

  ##########
end
