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

ActiveRecord::Schema.define(:version => 20100814222238) do

  create_table "asset_downloads", :force => true do |t|
    t.integer  "asset_id",   :null => false
    t.integer  "type_code",  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "assets", :force => true do |t|
    t.string   "uid"
    t.string   "path",                              :null => false
    t.integer  "size",                              :null => false
    t.string   "hex_checksum",                      :null => false
    t.boolean  "active",         :default => false, :null => false
    t.string   "hex_cipher_key",                    :null => false
    t.string   "hex_cipher_iv",                     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "contacts", :force => true do |t|
    t.string   "login",      :limit => 100,                   :null => false
    t.boolean  "active",                    :default => true, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "in_attachments", :force => true do |t|
    t.integer  "in_message_id",     :null => false
    t.integer  "asset_id",          :null => false
    t.string   "local_path_prefix", :null => false
    t.string   "relative_path",     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "in_messages", :force => true do |t|
    t.string   "uid",                           :null => false
    t.integer  "sender_id",                     :null => false
    t.datetime "sent_at",                       :null => false
    t.datetime "confirmed_at"
    t.string   "hex_cipher_key",                :null => false
    t.string   "hex_cipher_iv",                 :null => false
    t.integer  "head_asset_id"
    t.integer  "body_asset_id"
    t.string   "subject",        :limit => 200
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "nodes", :force => true do |t|
    t.string   "uid",             :null => false
    t.binary   "public_modulus",  :null => false
    t.integer  "public_exponent", :null => false
    t.string   "host",            :null => false
    t.integer  "port",            :null => false
    t.datetime "offline_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "out_attachments", :force => true do |t|
    t.integer  "out_message_id",    :null => false
    t.integer  "asset_id"
    t.string   "local_path_prefix", :null => false
    t.string   "relative_path",     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "out_message_requests", :force => true do |t|
    t.integer  "out_message_id",  :null => false
    t.integer  "contact_id",      :null => false
    t.string   "node_uid",        :null => false
    t.text     "node_public_key", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "out_messages", :force => true do |t|
    t.string   "uid"
    t.string   "subject",        :limit => 200, :default => "", :null => false
    t.text     "content",                       :default => "", :null => false
    t.integer  "status_code",                   :default => 0,  :null => false
    t.string   "hex_cipher_key",                                :null => false
    t.string   "hex_cipher_iv",                                 :null => false
    t.integer  "body_asset_id"
    t.integer  "head_asset_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "out_recipients", :force => true do |t|
    t.integer  "contact_id",     :null => false
    t.integer  "out_message_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "piece_download_attempts", :force => true do |t|
    t.integer  "piece_download_id",        :null => false
    t.integer  "piece_download_source_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "piece_download_sources", :force => true do |t|
    t.integer  "piece_download_id", :null => false
    t.integer  "node_id",           :null => false
    t.datetime "failed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "piece_downloads", :force => true do |t|
    t.integer  "asset_download_id",                :null => false
    t.integer  "piece_id",                         :null => false
    t.integer  "progress",          :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pieces", :force => true do |t|
    t.integer  "asset_id",             :null => false
    t.string   "uid"
    t.integer  "position",             :null => false
    t.integer  "offset",               :null => false
    t.integer  "size",                 :null => false
    t.integer  "transit_size",         :null => false
    t.string   "hex_transit_checksum", :null => false
    t.boolean  "compressed",           :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
