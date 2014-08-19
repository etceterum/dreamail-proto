class CreateNotices < ActiveRecord::Migration
  def self.up
    create_table :notices do |t|
      t.integer :user_id
      t.integer :announcement_id

      t.timestamps
    end
  end

  def self.down
    drop_table :notices
  end
end
