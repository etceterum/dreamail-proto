class CreatePieces < ActiveRecord::Migration
  def self.up
    create_table :pieces do |t|
      t.integer   :asset_id,              :null => false
      
      t.string    :uid,                   :default => nil
      t.integer   :position,              :null => false
      t.column    :offset, :bigint,       :null => false
      t.integer   :size,                  :null => false
      t.integer   :transit_size,          :null => false
      t.string    :hex_transit_checksum,  :null => false
      t.boolean   :compressed,            :null => false
      
      t.timestamps
    end
  end

  def self.down
    drop_table :pieces
  end
end
