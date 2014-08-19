class Node < ActiveRecord::Base
  ##########
  
  has_uid
  
  ##########

  validates_uniqueness_of :public_key, :on => :create
  
  ##########
  
  belongs_to  :user

  has_many    :owned_assets, :class_name => 'Asset', :foreign_key => 'owner_id', :dependent => :destroy
  has_many    :asset_links, :class_name => 'NodeAssetLink', :dependent => :destroy
  has_many    :assets, :through => :asset_links, :source => :asset

  ##########

  has_many    :announcements, :dependent => :destroy
  has_many    :messages

  ##########
end
