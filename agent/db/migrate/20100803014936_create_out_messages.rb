class CreateOutMessages < ActiveRecord::Migration
  def self.up
    create_table :out_messages do |t|
      
      t.string    :uid,             :default => nil
      
      t.string    :subject,         :null => false, :limit => 200, :default => ''
      t.column    :content,         :bigtext, :null => false, :limit => 1024*1024, :default => ''
      t.integer   :status_code,     :null => false, :default => 0
      
      t.string    :hex_cipher_key,  :null => false
      t.string    :hex_cipher_iv,   :null => false
      
      t.integer   :body_asset_id,   :default => nil
      t.integer   :head_asset_id,   :default => nil
      
      t.timestamps
    end
  end

  def self.down
    drop_table :out_messages
  end
end
