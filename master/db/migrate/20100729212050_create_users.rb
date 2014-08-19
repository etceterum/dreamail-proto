class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string  :login,         :null => false, :unique => true, :limit => 100
      t.string  :password_hash, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
