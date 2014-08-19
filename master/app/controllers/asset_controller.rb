class AssetController < TrackerController
  ##########
  
  def announce
    pieces_data = input[Proto::Tracker::PIECES_FIELD]
    bad_request unless pieces_data && pieces_data.is_a?(Array)
    
    asset = node.owned_assets.build
    new_pieces = []
    pieces_data.each_with_index do |p, i|
      bad_request unless p.is_a?(Array) && p.size == 2
      size = p[0]
      bad_request unless size.is_a?(Fixnum) && size > 0
      checksum = p[1]
      bad_request unless checksum.is_a?(String) && !checksum.empty?
      
      new_pieces << asset.pieces.build(:position => i, :size => size, :checksum => checksum)
    end
    
    node.assets << asset
    
    node.save!
    
    output[Proto::Tracker::ASSET_FIELD] = asset.uid
    pieces_output = []
    for p in new_pieces
      pieces_output << p.uid
    end
    output[Proto::Tracker::PIECES_FIELD] = pieces_output
  end
  
  ##########

  def activate
    asset_uids = input[Proto::Tracker::ASSETS_FIELD]
    bad_request unless asset_uids && asset_uids.is_a?(Array) && !asset_uids.empty?
    
    assets = []
    for asset_uid in asset_uids
      bad_request unless asset_uid.is_a?(String)
      asset = node.owned_assets.find_by_uid(asset_uid) or bad_request
      assets << asset
    end
    
    Asset.transaction do
      for asset in assets
        asset.activate!
      end
    end
  end
  
  ##########

  def track
    # locate asset
    asset_uid = input[Proto::Tracker::ASSET_FIELD]
    bad_request unless asset_uid && asset_uid.is_a?(String)
    asset = Asset.find_by_uid(asset_uid)
    bad_request unless asset
    
    # get piece mask
    piece_mask = input[Proto::Tracker::PIECES_FIELD]
    bad_request unless piece_mask && piece_mask.is_a?(Socketry::BooleanVector)
    bad_request unless piece_mask.empty? || piece_mask.size == asset.pieces.count
    
    # locate or create node-asset link
    node_asset_link = node.asset_links.find_by_asset_id(asset.id) || NodeAssetLink.new(:asset => asset, :node => node)
    node_asset_link.piece_bitmask = piece_mask.empty? ? nil : piece_mask.data

    # find what nodes have the missing pieces
    inv_piece_mask = ~piece_mask
    node_links = piece_mask.empty? ? [] : node_links = asset.node_links.with_pieces_in(inv_piece_mask.data).scoped({ :order => 'node_asset_links.updated_at desc' }).scoped({ :limit => Proto::Tracker::MAX_NODE_COUNT })
    
    # format response
    nodes_data = output[Proto::Tracker::NODES_FIELD] = []
    for node_link in node_links
      node = node_link.node
      public_key = OpenSSL::PKey::RSA.new(node.public_key)
      
      # logger.info "PK N: #{public_key.n}"
      # logger.info "PK E: #{public_key.e}"
      
      node_data = {
        :uid => node.uid,
        :pieces => node_link.piece_bitmask || BooleanVector.new(0),
        :host => node.reported_host || node.detected_host,
        :port => node.reported_port || Proto::DEFAULT_PORT,
        :public_key => { :n => public_key.n.to_s(2), :e => public_key.e.to_i }
      }
      nodes_data << node_data
    end
    nodes_data.sort_by { rand }
      
    # update node-asset link
    node_asset_link.save!
  end

  ##########
end
