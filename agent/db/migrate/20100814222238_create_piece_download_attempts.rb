class CreatePieceDownloadAttempts < ActiveRecord::Migration
  def self.up
    create_table :piece_download_attempts do |t|
      
      t.integer   :piece_download_id,         :null => false, :unique => true
      t.integer   :piece_download_source_id,  :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :piece_download_attempts
  end
end
