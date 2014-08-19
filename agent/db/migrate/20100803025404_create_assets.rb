class CreateAssets < ActiveRecord::Migration
  def self.up
    create_table :assets do |t|
      t.string  :uid,               :default => nil
      t.string  :path,              :null => false
      t.column  :size,              :bigint, :null => false
      t.string  :hex_checksum,      :null => false
      t.boolean :active,            :null => false, :default => false

      t.string    :hex_cipher_key,  :null => false
      t.string    :hex_cipher_iv,   :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :assets
  end
end
