class CreateContacts < ActiveRecord::Migration
  def self.up
    create_table :contacts do |t|
      t.string  :login, :null => false, :unique => true, :limit => 100
      t.boolean :active, :null => false, :default => true

      t.timestamps
    end
  end

  def self.down
    drop_table :contacts
  end
end
