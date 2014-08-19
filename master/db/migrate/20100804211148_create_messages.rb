class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
      t.integer   :node_id,       :null => false
      t.integer   :notice_id,     :null => false
      t.text      :auth,          :default => nil
      t.text      :data,          :default => nil
      t.datetime  :sent_at,       :default => nil
      t.datetime  :confirmed_at,  :default => nil

      t.timestamps
    end
  end

  def self.down
    drop_table :messages
  end
end
