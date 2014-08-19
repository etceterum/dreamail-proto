class Asset < ActiveRecord::Base
  ##########

  has_uid
  
  ##########

  def activate!
    return if active?
    self.active = true
    save!
  end

  ##########
  
  belongs_to  :owner, :class_name => 'Node', :foreign_key => 'owner_id'
  has_many    :pieces, :dependent => :destroy
  has_many    :node_links, :class_name => 'NodeAssetLink', :dependent => :destroy
  has_many    :nodes, :through => :node_links

  ##########
end
