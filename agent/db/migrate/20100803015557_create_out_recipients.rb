class CreateOutRecipients < ActiveRecord::Migration
  def self.up
    create_table :out_recipients do |t|
      t.integer :contact_id,      :null => false
      t.integer :out_message_id,  :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :out_recipients
  end
end
