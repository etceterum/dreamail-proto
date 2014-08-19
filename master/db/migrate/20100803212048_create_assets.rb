class CreateAssets < ActiveRecord::Migration
  def self.up
    create_table :assets do |t|
      t.integer :owner_id,  :null => false
      t.string  :uid,       :null => false, :unique => true
      t.boolean :active,    :null => false, :default => false

      t.timestamps
    end
  end

  def self.down
    drop_table :assets
  end
end
