class CreateAssetDownloads < ActiveRecord::Migration
  def self.up
    create_table :asset_downloads do |t|
      t.integer   :asset_id,        :null => false
      t.integer   :type_code,       :null => false
      
      t.datetime  :track_at,        :default => nil
      t.integer   :track_interval,  :default => nil

      t.timestamps
    end
  end

  def self.down
    drop_table :asset_downloads
  end
end
