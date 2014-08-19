class CreateOutAttachments < ActiveRecord::Migration
  def self.up
    create_table :out_attachments do |t|
      t.integer :out_message_id,    :null => false
      t.integer :asset_id,          :default => nil
      t.string  :local_path_prefix, :null => false
      t.string  :relative_path,     :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :out_attachments
  end
end
