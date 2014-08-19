class CreatePieces < ActiveRecord::Migration
  def self.up
    create_table :pieces do |t|
      t.integer :asset_id,      :null => false
      
      t.string  :uid,           :null => false
      t.integer :position,      :null => false
      t.integer :size,          :null => false
      t.string  :hex_checksum,  :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :pieces
  end
end
