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

ActiveRecord::Schema.define(:version => 20110625050043) do

  create_table "contents", :force => true do |t|
    t.string   "name",                         :null => false
    t.integer  "duration",                     :null => false
    t.datetime "start_time"
    t.datetime "end_time"
    t.text     "data"
    t.integer  "user_id",                      :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type",                         :null => false
    t.boolean  "is_public",  :default => true, :null => false
  end

  add_index "contents", ["end_time"], :name => "index_contents_on_end_time"
  add_index "contents", ["is_public"], :name => "index_contents_on_public"
  add_index "contents", ["name"], :name => "index_contents_on_name"
  add_index "contents", ["start_time"], :name => "index_contents_on_start_time"
  add_index "contents", ["type"], :name => "index_contents_on_type"
  add_index "contents", ["user_id"], :name => "index_contents_on_user_id"

  create_table "feeds", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_read_only",   :default => false, :null => false
    t.boolean  "is_public",      :default => true,  :null => false
    t.boolean  "is_viewable",    :default => true,  :null => false
    t.boolean  "is_submittable", :default => true,  :null => false
  end

  add_index "feeds", ["group_id"], :name => "index_feeds_on_group_id"
  add_index "feeds", ["is_public"], :name => "index_feeds_on_is_public"
  add_index "feeds", ["is_read_only"], :name => "index_feeds_on_is_read_only"
  add_index "feeds", ["name"], :name => "index_feeds_on_name"

  create_table "fields", :force => true do |t|
    t.string   "name"
    t.integer  "kind_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "groups", :force => true do |t|
    t.string   "name",                         :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_public",  :default => true, :null => false
  end

  add_index "groups", ["is_public"], :name => "index_groups_on_public"
  add_index "groups", ["name"], :name => "index_groups_on_name"

  create_table "media", :force => true do |t|
    t.integer  "attachable_id"
    t.string   "attachable_type"
    t.string   "key"
    t.string   "file_name"
    t.string   "file_type"
    t.integer  "file_size"
    t.binary   "file_data",       :limit => 10485760
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "memberships", :force => true do |t|
    t.integer  "user_id",                         :null => false
    t.integer  "group_id",                        :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_admin",     :default => false, :null => false
    t.boolean  "is_moderator", :default => false, :null => false
  end

  add_index "memberships", ["group_id"], :name => "index_memberships_on_group_id"
  add_index "memberships", ["is_admin"], :name => "index_memberships_on_admin"
  add_index "memberships", ["is_moderator"], :name => "index_memberships_on_moderator"
  add_index "memberships", ["user_id"], :name => "index_memberships_on_user_id"

  create_table "positions", :force => true do |t|
    t.text     "style"
    t.decimal  "top",         :default => 0.0
    t.decimal  "left",        :default => 0.0
    t.decimal  "bottom",      :default => 0.0
    t.decimal  "right",       :default => 0.0
    t.integer  "field_id"
    t.integer  "template_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "screens", :force => true do |t|
    t.string   "name"
    t.string   "location"
    t.boolean  "is_public"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.integer  "template_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "width"
    t.integer  "height"
  end

  create_table "submissions", :force => true do |t|
    t.integer  "content_id",                      :null => false
    t.integer  "feed_id",                         :null => false
    t.boolean  "is_moderated", :default => false, :null => false
    t.integer  "moderator_id"
    t.integer  "duration",                        :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "submissions", ["content_id"], :name => "index_submissions_on_content_id"
  add_index "submissions", ["feed_id"], :name => "index_submissions_on_feed_id"
  add_index "submissions", ["is_moderated"], :name => "index_submissions_on_moderation_flag"
  add_index "submissions", ["moderator_id"], :name => "index_submissions_on_moderator_id"

  create_table "subscriptions", :force => true do |t|
    t.integer  "feed_id"
    t.integer  "field_id"
    t.integer  "screen_id"
    t.integer  "weight"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "templates", :force => true do |t|
    t.string   "name"
    t.string   "author"
    t.boolean  "is_hidden"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                                 :default => "",    :null => false
    t.string   "encrypted_password",     :limit => 128, :default => "",    :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "first_name"
    t.string   "last_name"
    t.boolean  "is_super_user",                         :default => false, :null => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["is_super_user"], :name => "index_users_on_super_user"
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
