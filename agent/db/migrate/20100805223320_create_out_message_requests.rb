class CreateOutMessageRequests < ActiveRecord::Migration
  def self.up
    create_table :out_message_requests do |t|
      t.integer   :out_message_id,  :null => false
      t.integer   :contact_id,      :null => false
      t.string    :node_uid,        :null => false
      t.text      :node_public_key, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :out_message_requests
  end
end
