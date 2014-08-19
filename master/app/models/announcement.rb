class Announcement < ActiveRecord::Base
  ##########

  has_uid

  ##########
  
  belongs_to  :node
  has_many    :notices, :dependent => :destroy
  has_many    :recipients, :through => :notices, :source => :user
  
  ##########
end
