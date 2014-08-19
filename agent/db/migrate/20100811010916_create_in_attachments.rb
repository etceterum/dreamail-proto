class CreateInAttachments < ActiveRecord::Migration
  def self.up
    create_table :in_attachments do |t|
      t.integer :in_message_id,     :null => false
      t.integer :asset_id,          :default => nil
      
      t.string  :relative_path,     :null => false
      t.column  :size, :bigint,     :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :in_attachments
  end
end
