class Message < ActiveRecord::Base
  ##########
  
  belongs_to  :node
  has_one     :user, :through => :node

  belongs_to  :notice
  has_one     :announcement, :through => :notice

  ##########

  named_scope :not_sent,      :conditions => { :sent_at => nil }
  named_scope :sent,          :conditions => 'messages.sent_at is not null'
  named_scope :not_confirmed, :conditions => { :confirmed_at => nil }
  named_scope :ordered,       :order => 'messages.id asc'

  ##########

  def confirmed?
    !confirmed_at.nil?
  end

  ##########
end
