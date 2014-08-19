class Piece < ActiveRecord::Base
  ##########
  
  belongs_to  :asset
  has_one     :download, :class_name => 'PieceDownload', :dependent => :destroy
  
  ##########

  named_scope :positioned, :order => 'position asc'

  ##########
  
  def announced?
    !uid.nil?
  end
  
  ##########

  def complete?
    download.nil? || download.progress == transit_size
  end

  ##########

  def metainfo
    raise Socketry::InternalError.new unless announced?

    data = {
      :uid => uid,
      :offset => offset,
      :size => size,
      :transit => {
        :size => transit_size,
        :checksum => hex_transit_checksum,
        :compressed => compressed?
      }
    }
  end

  ##########

  def compile_info
    data = {
      :input => {
        :offset => offset,
        :size => size
      },
      :output => {
        :size => transit_size,
        :hash => transit_checksum,
        :compressed => compressed?
      }
    }
  end

  ##########

  def transit_checksum
    Socketry::Encoder.hex_to_bin(hex_transit_checksum)
  end

  def transit_checksum=(bin_transit_checksum)
    self.hex_transit_checksum = Socketry::Encoder.bin_to_hex(bin_transit_checksum)
  end
  
  ##########

  def download_complete!(data)
    asset.place_piece_data(data, compile_info)
  end

  ##########
end
