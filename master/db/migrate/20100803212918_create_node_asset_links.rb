class CreateNodeAssetLinks < ActiveRecord::Migration
  def self.up
    create_table :node_asset_links do |t|
      t.integer :node_id,       :null => false
      t.integer :asset_id,      :null => false
      
      # nil in this field means that the node has all pieces of the asset
      t.string  :piece_bitmask, :default => nil

      t.timestamps
    end
  end

  def self.down
    drop_table :node_asset_links
  end
end
