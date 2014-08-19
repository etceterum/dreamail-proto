class CreateAnnouncements < ActiveRecord::Migration
  def self.up
    create_table :announcements do |t|
      t.integer :node_id, :null => false
      t.string  :uid,     :null => false, :unique => true

      t.timestamps
    end
  end

  def self.down
    drop_table :announcements
  end
end
