# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100810034443) do

  create_table "announcements", :force => true do |t|
    t.integer  "node_id",    :null => false
    t.string   "uid",        :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "assets", :force => true do |t|
    t.integer  "owner_id",                      :null => false
    t.string   "uid",                           :null => false
    t.boolean  "active",     :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bitmask_values", :force => true do |t|
    t.integer "bit_number",  :null => false
    t.integer "byte_number", :null => false
    t.integer "bit_value",   :null => false
  end

  add_index "bitmask_values", ["bit_number"], :name => "index_bitmask_values_on_bit_number", :unique => true
  add_index "bitmask_values", ["bit_value"], :name => "index_bitmask_values_on_bit_value"
  add_index "bitmask_values", ["byte_number"], :name => "index_bitmask_values_on_byte_number"

  create_table "connections", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.integer  "contact_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "messages", :force => true do |t|
    t.integer  "node_id",      :null => false
    t.integer  "notice_id",    :null => false
    t.text     "auth"
    t.text     "data"
    t.datetime "sent_at"
    t.datetime "confirmed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "node_asset_links", :force => true do |t|
    t.integer  "node_id",       :null => false
    t.integer  "asset_id",      :null => false
    t.string   "piece_bitmask"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "nodes", :force => true do |t|
    t.integer  "user_id",          :null => false
    t.string   "uid",              :null => false
    t.text     "public_key",       :null => false
    t.string   "detected_host"
    t.string   "reported_host"
    t.integer  "reported_port"
    t.datetime "session_start_at"
    t.datetime "session_end_at"
    t.integer  "last_message_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "notices", :force => true do |t|
    t.integer  "user_id"
    t.integer  "announcement_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pieces", :force => true do |t|
    t.integer  "asset_id",     :null => false
    t.string   "uid",          :null => false
    t.integer  "position",     :null => false
    t.integer  "size",         :null => false
    t.string   "hex_checksum", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "login",         :limit => 100, :null => false
    t.string   "password_hash",                :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
