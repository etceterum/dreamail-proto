class CreatePieceDownloadSources < ActiveRecord::Migration
  def self.up
    create_table :piece_download_sources do |t|
      
      t.integer   :piece_download_id, :null => false
      t.integer   :node_id,           :null => false
      
      t.datetime  :failed_at,         :default => nil

      t.timestamps
    end
  end

  def self.down
    drop_table :piece_download_sources
  end
end
