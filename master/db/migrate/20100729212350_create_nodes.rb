class CreateNodes < ActiveRecord::Migration
  def self.up
    create_table :nodes do |t|
      t.integer   :user_id,             :null => false
      t.string    :uid,                 :null => false, :unique => true
      t.text      :public_key,          :null => false, :unique => true

      t.string    :detected_host,       :default => nil
      t.string    :reported_host,       :default => nil
      t.integer   :reported_port,       :default => nil
      
      t.datetime  :session_start_at,    :default => nil
      t.datetime  :session_end_at,      :default => nil
      
      t.integer   :last_message_id,     :default => nil

      t.timestamps
    end
  end

  def self.down
    drop_table :nodes
  end
end
