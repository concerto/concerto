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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20191016022505) do

  create_table "activities", force: :cascade do |t|
    t.integer  "trackable_id"
    t.string   "trackable_type"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.string   "key"
    t.text     "parameters"
    t.integer  "recipient_id"
    t.string   "recipient_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "activities", ["owner_id", "owner_type"], name: "index_activities_on_owner_id_and_owner_type"
  add_index "activities", ["recipient_id", "recipient_type"], name: "index_activities_on_recipient_id_and_recipient_type"
  add_index "activities", ["trackable_id", "trackable_type"], name: "index_activities_on_trackable_id_and_trackable_type"

  create_table "concerto_configs", force: :cascade do |t|
    t.string  "key"
    t.string  "value"
    t.string  "value_type"
    t.string  "value_default"
    t.string  "name"
    t.string  "category"
    t.text    "description"
    t.boolean "plugin_config"
    t.integer "plugin_id"
    t.boolean "hidden",        default: false
    t.boolean "can_cache",     default: true
    t.integer "seq_no"
    t.string  "select_values"
  end

  add_index "concerto_configs", ["key"], name: "index_concerto_configs_on_key", unique: true

  create_table "concerto_hardware_players", force: :cascade do |t|
    t.string   "ip_address"
    t.integer  "screen_id"
    t.boolean  "activated"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "screen_on_off"
  end

  create_table "concerto_plugins", force: :cascade do |t|
    t.boolean  "enabled"
    t.string   "gem_name"
    t.string   "gem_version"
    t.string   "source"
    t.string   "source_url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "contents", force: :cascade do |t|
    t.string   "name"
    t.integer  "duration"
    t.datetime "start_time"
    t.datetime "end_time"
    t.text     "data",           limit: 16777215
    t.integer  "user_id"
    t.integer  "kind_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type"
    t.integer  "parent_id"
    t.integer  "children_count",                  default: 0
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0
    t.integer  "attempts",   default: 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority"

  create_table "feeds", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "parent_id"
    t.integer  "group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_viewable",    default: true
    t.boolean  "is_submittable", default: true
    t.text     "content_types"
  end

  add_index "feeds", ["parent_id"], name: "index_feeds_on_parent_id"

  create_table "field_configs", force: :cascade do |t|
    t.integer  "field_id"
    t.string   "key"
    t.string   "value"
    t.integer  "screen_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fields", force: :cascade do |t|
    t.string   "name"
    t.integer  "kind_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "groups", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "narrative"
  end

  create_table "kinds", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "media", force: :cascade do |t|
    t.integer  "attachable_id"
    t.string   "attachable_type"
    t.string   "key"
    t.string   "file_name"
    t.string   "file_type"
    t.integer  "file_size"
    t.binary   "file_data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "media", ["attachable_id", "attachable_type"], name: "index_media_on_attachable_id_and_attachable_type"

  create_table "memberships", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "level",          default: 1
    t.integer  "permissions"
    t.boolean  "receive_emails"
  end

  add_index "memberships", ["receive_emails"], name: "index_memberships_on_receive_emails"

  create_table "pages", force: :cascade do |t|
    t.string   "category"
    t.string   "title"
    t.string   "language"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
  end

  create_table "positions", force: :cascade do |t|
    t.text     "style"
    t.decimal  "top",         precision: 6, scale: 5, default: 0.0
    t.decimal  "left",        precision: 6, scale: 5, default: 0.0
    t.decimal  "bottom",      precision: 6, scale: 5, default: 0.0
    t.decimal  "right",       precision: 6, scale: 5, default: 0.0
    t.integer  "field_id"
    t.integer  "template_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "screens", force: :cascade do |t|
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
    t.datetime "frontend_updated_at"
    t.string   "authentication_token"
    t.string   "time_zone"
    t.string   "locale"
  end

  create_table "submissions", force: :cascade do |t|
    t.integer  "content_id"
    t.integer  "feed_id"
    t.boolean  "moderation_flag"
    t.integer  "moderator_id"
    t.integer  "duration"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "moderation_reason"
    t.datetime "pending_notification_sent"
    t.integer  "seq_no"
  end

  add_index "submissions", ["feed_id", "seq_no"], name: "index_submissions_on_feed_id_and_seq_no"

  create_table "subscriptions", force: :cascade do |t|
    t.integer  "feed_id"
    t.integer  "field_id"
    t.integer  "screen_id"
    t.integer  "weight"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "templates", force: :cascade do |t|
    t.string   "name"
    t.string   "author"
    t.boolean  "is_hidden",       default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "original_width"
    t.integer  "original_height"
    t.integer  "owner_id"
    t.string   "owner_type"
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                            default: "",    null: false
    t.string   "encrypted_password",               default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "locale"
    t.boolean  "is_admin",                         default: false
    t.boolean  "receive_moderation_notifications"
    t.string   "time_zone"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true

end
