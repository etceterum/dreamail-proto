class Contact < ActiveRecord::Base
  ##########
  
  named_scope :active, :conditions => { :active => true }

  ##########

  has_many :out_recipients, :dependent => :destroy

  ##########

  def name
    login.sub(/@.*/, '').capitalize
  end

  ##########
end
