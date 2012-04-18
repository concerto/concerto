# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120418142310) do

  create_table "contents", :force => true do |t|
    t.string   "name"
    t.integer  "duration"
    t.datetime "start_time"
    t.datetime "end_time"
    t.text     "data"
    t.integer  "user_id"
    t.integer  "kind_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "type"
  end

  create_table "feeds", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "parent_id"
    t.integer  "group_id"
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
    t.boolean  "is_viewable",    :default => true
    t.boolean  "is_submittable", :default => true
  end

  create_table "fields", :force => true do |t|
    t.string   "name"
    t.integer  "kind_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "groups", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "kinds", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "media", :force => true do |t|
    t.integer  "attachable_id"
    t.string   "attachable_type"
    t.string   "key"
    t.string   "file_name"
    t.string   "file_type"
    t.integer  "file_size"
    t.binary   "file_data",       :limit => 10485760
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
  end

  create_table "memberships", :force => true do |t|
    t.integer  "user_id"
    t.integer  "group_id"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
    t.integer  "level",      :default => 1
  end

  create_table "positions", :force => true do |t|
    t.text     "style"
    t.decimal  "top",         :precision => 6, :scale => 5, :default => 0.0
    t.decimal  "left",        :precision => 6, :scale => 5, :default => 0.0
    t.decimal  "bottom",      :precision => 6, :scale => 5, :default => 0.0
    t.decimal  "right",       :precision => 6, :scale => 5, :default => 0.0
    t.integer  "field_id"
    t.integer  "template_id"
    t.datetime "created_at",                                                 :null => false
    t.datetime "updated_at",                                                 :null => false
  end

  create_table "screens", :force => true do |t|
    t.string   "name"
    t.string   "location"
    t.boolean  "is_public"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.integer  "template_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.integer  "width"
    t.integer  "height"
  end

  create_table "submissions", :force => true do |t|
    t.integer  "content_id"
    t.integer  "feed_id"
    t.boolean  "moderation_flag"
    t.integer  "moderator_id"
    t.integer  "duration"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.text     "moderation_reason"
  end

  create_table "subscriptions", :force => true do |t|
    t.integer  "feed_id"
    t.integer  "field_id"
    t.integer  "screen_id"
    t.integer  "weight"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "templates", :force => true do |t|
    t.string   "name"
    t.string   "author"
    t.boolean  "is_hidden"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
    t.integer  "original_width"
    t.integer  "original_height"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                  :default => "",    :null => false
    t.string   "encrypted_password",     :default => "",    :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.string   "first_name"
    t.string   "last_name"
    t.string   "locale"
    t.boolean  "is_admin",               :default => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
