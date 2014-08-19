require 'digest/md5'

class User < ActiveRecord::Base
  ##########

  PASSWORD_SALT = '0058f84bfa97a34dae7d158c8279e6d9'

  ##########

  validates_presence_of   :login
  validates_uniqueness_of :login
  validates_format_of     :login, :with => Socketry::Regex.email
  
  validates_length_of     :password_hash, :is => 32

  ##########

  has_many  :nodes, :dependent => :destroy
  
  has_many  :connections, :dependent => :destroy
  has_many  :contacts, :through => :connections, :source => :contact

  has_many  :reverse_connections, :class_name => 'Connection', :foreign_key => 'contact_id', :dependent => :destroy
  has_many  :reverse_contacts, :through => :reverse_connections, :source => :user
  
  has_many  :notices, :dependent => :destroy
  
  ##########

  def password=(p)
    self.password_hash = mangle_password(p)
  end
  
  def password_correct?(p)
    password_hash == mangle_password(p)
  end
  
  ##########
  
  def connected_with?(other_user, both_ways = true)
    connections.find_by_contact_id(other_user.id) && (!both_ways || other_user.connected_with?(self, false))
  end

  def connect_with!(other_user, both_ways = true)
    unless connected_with?(other_user, false)
      connections.create(:contact_id => other_user.id)
    end
    other_user.connect_with!(self, false) if both_ways
  end

  ##########

  private
  
  def mangle_password(p)
    Digest::MD5.hexdigest(PASSWORD_SALT + p)
  end

  ##########
end
