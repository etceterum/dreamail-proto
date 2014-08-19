class CreateBitmaskValues < ActiveRecord::Migration
  def self.up
    create_table :bitmask_values do |t|
      t.integer :bit_number,  :null => false, :unique => true
      t.integer :byte_number, :null => false
      t.integer :bit_value,   :null => false

      # t.timestamps
    end
    
    add_index :bitmask_values, :bit_number, :unique => true
    add_index :bitmask_values, :byte_number
    add_index :bitmask_values, :bit_value
    
  end

  def self.down
    remove_index :bitmask_values, :bit_number
    remove_index :bitmask_values, :byte_number
    remove_index :bitmask_values, :bit_value

    drop_table :bitmask_values
  end
end
