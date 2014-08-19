class CreateInMessages < ActiveRecord::Migration
  def self.up
    create_table :in_messages do |t|
      t.string    :uid,               :null => false, :unique => true
      t.integer   :sender_id,         :null => false
      t.datetime  :sent_at,           :null => false
      t.datetime  :confirmed_at,      :default => nil
      t.string    :hex_cipher_key,    :null => false
      t.string    :hex_cipher_iv,     :null => false
      t.integer   :head_asset_id,     :default => nil
      t.integer   :body_asset_id,     :default => nil

      t.string    :subject,           :limit => 200, :default => nil
      t.column    :content,           :bigtext, :limit => 1024*1024, :default => nil
      t.datetime  :received_at,       :default => nil
      
      t.datetime  :read_at,           :default => nil

      t.timestamps
    end
  end

  def self.down
    drop_table :in_messages
  end
end
