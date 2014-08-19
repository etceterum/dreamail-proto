class CreatePieceDownloads < ActiveRecord::Migration
  def self.up
    create_table :piece_downloads do |t|
      t.integer :asset_download_id, :null => false
      t.integer :piece_id,          :null => false
      # t.integer :progress,          :null => false, :default => 0
      t.boolean :complete,          :null => false, :default => false

      t.timestamps
    end
  end

  def self.down
    drop_table :piece_downloads
  end
end
