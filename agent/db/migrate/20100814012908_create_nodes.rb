class CreateNodes < ActiveRecord::Migration
  def self.up
    create_table :nodes do |t|
      t.string    :uid,               :null => false
      t.binary    :public_modulus,    :null => false
      t.integer   :public_exponent,   :null => false
      t.string    :host,              :null => false
      t.integer   :port,              :null => false

      t.datetime  :offline_at,        :default => nil

      t.timestamps
    end
  end

  def self.down
    drop_table :nodes
  end
end
