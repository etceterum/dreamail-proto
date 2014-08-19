class Piece < ActiveRecord::Base
  ##########

  has_uid

  ##########
  
  belongs_to  :asset
  
  ##########

  def checksum
    Socketry::Encoder.hex_to_bin(hex_checksum)
  end

  def checksum=(bin_checksum)
    self.hex_checksum = Socketry::Encoder.bin_to_hex(bin_checksum)
  end
  
  ##########
end
