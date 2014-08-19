class NodeAssetLink < ActiveRecord::Base
  ##########
  
  belongs_to  :node
  belongs_to  :asset
  
  ##########

  def self.with_pieces_in(bitmask)
    scope = self.scoped({})
    scope = scope.scoped({
      :joins => [
        'left outer join bitmask_values as bv1 on ((bv1.bit_value & ascii(substr(node_asset_links.piece_bitmask, bv1.byte_number, 1))) = bv1.bit_value)',
        'left outer join bitmask_values as bv2 on bv1.bit_number = bv2.bit_number'
      ]
    })
    scope = scope.scoped({
      :conditions => [
        '(node_asset_links.piece_bitmask is null) or ((bv2.bit_value & ascii(substr(?, bv2.byte_number, 1))) = bv2.bit_value)', bitmask
        ]
    })
    scope = scope.scoped({
      :group => 'node_asset_links.id'
    })
    
    scope
  end

  ##########
end
