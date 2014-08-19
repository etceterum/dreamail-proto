class Notice < ActiveRecord::Base
  ##########
  
  belongs_to  :user
  belongs_to  :announcement
  
  has_many    :messages, :dependent => :destroy
  
  ##########

  named_scope :ordered, :order => 'notices.id asc'
  named_scope :newer_than, lambda { |time| { :conditions => ['notices.created_at >= ?', time] } }

  # 
  # named_scope :for_node_id, :include => [{:user => :nodes}] do |node_id|
  #   { :conditions => ['nodes.id = ?', node_id] }
  # end
  # named_scope :without_message, :include => :messages do
  #   { :conditions => 'messages.id is not null' }
  # end

  ##########
end
