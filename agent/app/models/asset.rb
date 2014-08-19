class Asset < ActiveRecord::Base
  ##########
  
  has_one     :download, :class_name => 'AssetDownload', :dependent => :destroy
  has_many    :pieces, :dependent => :destroy

  ##########

  named_scope :downloading, :include => :download, :conditions => 'asset_downloads.id is not null'

  ##########

  def announced?
    !uid.nil?
  end

  ##########

  def activate!
    raise Socketry::InternalError if active?
    
    self.active = true
    save!
  end

  ##########

  def compile(compiler, path, &block)
    raise Socketry::InternalError.new("Asset already compiled") unless new_record? && pieces.empty?

    result = compiler.compile_file(path, &block)
    
    self.path = path
    self.size = result[:input][:size]
    self.checksum = result[:input][:hash]
    self.cipher_key = compiler.options[:cipher_key]
    self.cipher_iv = compiler.options[:cipher_iv]
    
    result[:pieces].each_with_index do |p, i|
      pieces.build(
        :position => i,
        :offset => p[:input][:offset],
        :size => p[:input][:size],
        :transit_size => p[:output][:size],
        :transit_checksum => p[:output][:hash],
        :compressed => !!p[:output][:compressed]
        )
    end

    self
  end
  
  def compile_from_string(compiler, string, filename, &block)
    path = File.join(Socketry::Config::PRIVATE_LOCAL_ASSETS_ROOT, filename)
    File.open(path, 'wb') do |file|
      file.write(string)
    end
    
    compile(compiler, path, &block)
  end
  
  ##########

  def metainfo
    raise Socketry::InternalError.new unless announced?
    
    data = { 
      :uid => uid,
      :size => size,
      :checksum => hex_checksum,
      :pieces => []
    }
    pieces_data = data[:pieces]
    for piece in pieces.positioned
      pieces_data << piece.metainfo
    end
    data
  end

  ##########

  def checksum
    Socketry::Encoder.hex_to_bin(hex_checksum)
  end

  def checksum=(bin_checksum)
    self.hex_checksum = Socketry::Encoder.bin_to_hex(bin_checksum)
  end

  ##########

  def cipher_key
    Socketry::Encoder.hex_to_bin(hex_cipher_key)
  end
  
  def cipher_key=(bin_cipher_key)
    self.hex_cipher_key = Socketry::Encoder.bin_to_hex(bin_cipher_key)
  end

  def cipher_iv
    Socketry::Encoder.hex_to_bin(hex_cipher_iv)
  end
  
  def cipher_iv=(bin_cipher_iv)
    self.hex_cipher_iv = Socketry::Encoder.bin_to_hex(bin_cipher_iv)
  end

  ##########

  def place_piece_data(piece_data, piece_info)
    compiler = Socketry::Compiler.new(
      :max_piece_size => Socketry::Proto::MAX_PIECE_SIZE,
      :hash_type => Socketry::Proto::CHECKSUM_TYPE,
      :cipher_type => Socketry::Proto::CIPHER_TYPE,
      :cipher_key => cipher_key,
      :cipher_iv => cipher_iv
      )
      compiler.insert_piece_into_file(path, piece_data, piece_info)
  end

  ##########

  def downloading?
    !download.nil?
  end
  
  def here?
    !downloading?
  end

  ##########
end
