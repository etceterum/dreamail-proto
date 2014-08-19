require 'openssl'

class Node < ActiveRecord::Base
  ##########

  FORGIVENESS_TIMEOUT = 120

  ##########

  has_many    :piece_download_sources, :dependent => :destroy
  has_many    :piece_downloads, :through => :piece_download_sources, :source => :download
  has_many    :asset_downloads, :through => :piece_downloads

  ##########

  # named_scope :to_be_forgiven, :conditions => 

  ##########

  def public_key
    @public_key ||= init_public_key
  end

  ##########
  private
  
  def init_public_key
    modulus = OpenSSL::BN.new(public_modulus, 2)
    exponent = OpenSSL::BN.new(public_exponent.to_s)
    public_key = OpenSSL::PKey::RSA.new
    public_key.n = modulus
    public_key.e = exponent
    public_key
  end

  ##########
end
