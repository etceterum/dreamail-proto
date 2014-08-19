class DownloadController < ServiceController
  
  def piece
    
    piece_info = input[:piece]
    bad_request unless piece_info && piece_info.is_a?(Hash)
    
    piece_uid = piece_info[:uid]
    bad_request unless piece_uid && piece_uid.is_a?(String)
    piece = Piece.find_by_uid(piece_uid)
    not_found unless piece && piece.complete?
    
    # as an added measure of security, we also require the client to send us the transit checksum value for the piece
    piece_checksum = piece_info[:checksum]
    bad_request unless piece_checksum && piece_checksum.is_a?(String)
    not_found unless piece.transit_checksum == piece_checksum
    
    # can now extract and serve piece data
    asset = piece.asset
    compiler = Compiler.new(
      :max_piece_size => Proto::MAX_PIECE_SIZE,
      :hash_type => Proto::CHECKSUM_TYPE,
      :cipher_type => Proto::CIPHER_TYPE,
      :cipher_key => asset.cipher_key,
      :cipher_iv => asset.cipher_iv
      )
    piece_data = compiler.extract_piece_from_file(asset.path, piece.compile_info)
    
    output[:piece] = piece_data
  end
  
end
