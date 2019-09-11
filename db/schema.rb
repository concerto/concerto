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

ActiveRecord::Schema.define(version: 20190911195651) do

  create_table "activities", force: :cascade do |t|
    t.integer  "trackable_id",   limit: 4
    t.string   "trackable_type", limit: 255
    t.integer  "owner_id",       limit: 4
    t.string   "owner_type",     limit: 255
    t.string   "key",            limit: 255
    t.text     "parameters",     limit: 65535
    t.integer  "recipient_id",   limit: 4
    t.string   "recipient_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "activities", ["owner_id", "owner_type"], name: "index_activities_on_owner_id_and_owner_type", using: :btree
  add_index "activities", ["recipient_id", "recipient_type"], name: "index_activities_on_recipient_id_and_recipient_type", using: :btree
  add_index "activities", ["trackable_id", "trackable_type"], name: "index_activities_on_trackable_id_and_trackable_type", using: :btree

  create_table "concerto_configs", force: :cascade do |t|
    t.string  "key",           limit: 255
    t.string  "value",         limit: 255
    t.string  "value_type",    limit: 255
    t.string  "value_default", limit: 255
    t.string  "name",          limit: 255
    t.string  "category",      limit: 255
    t.text    "description",   limit: 65535
    t.boolean "plugin_config"
    t.integer "plugin_id",     limit: 4
    t.boolean "hidden",                      default: false
    t.boolean "can_cache",                   default: true
    t.integer "seq_no",        limit: 4
    t.string  "select_values", limit: 255
  end

  add_index "concerto_configs", ["key"], name: "index_concerto_configs_on_key", unique: true, using: :btree

  create_table "concerto_hardware_players", force: :cascade do |t|
    t.string   "ip_address",    limit: 255
    t.integer  "screen_id",     limit: 4
    t.boolean  "activated"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "screen_on_off", limit: 255
  end

  create_table "concerto_plugins", force: :cascade do |t|
    t.boolean  "enabled"
    t.string   "gem_name",    limit: 255
    t.string   "gem_version", limit: 255
    t.string   "source",      limit: 255
    t.string   "source_url",  limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "contents", force: :cascade do |t|
    t.string   "name",           limit: 255
    t.integer  "duration",       limit: 4
    t.datetime "start_time"
    t.datetime "end_time"
    t.text     "data",           limit: 16777215
    t.integer  "user_id",        limit: 4
    t.integer  "kind_id",        limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type",           limit: 255
    t.integer  "parent_id",      limit: 4
    t.integer  "children_count", limit: 4,        default: 0
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   limit: 4,     default: 0
    t.integer  "attempts",   limit: 4,     default: 0
    t.text     "handler",    limit: 65535
    t.text     "last_error", limit: 65535
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: 255
    t.string   "queue",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "feeds", force: :cascade do |t|
    t.string   "name",           limit: 255
    t.text     "description",    limit: 65535
    t.integer  "parent_id",      limit: 4
    t.integer  "group_id",       limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_viewable",                  default: true
    t.boolean  "is_submittable",               default: true
    t.text     "content_types",  limit: 65535
  end

  add_index "feeds", ["parent_id"], name: "index_feeds_on_parent_id", using: :btree

  create_table "field_configs", force: :cascade do |t|
    t.integer  "field_id",   limit: 4
    t.string   "key",        limit: 255
    t.string   "value",      limit: 255
    t.integer  "screen_id",  limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fields", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.integer  "kind_id",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "groups", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "narrative",  limit: 65535
  end

  create_table "kinds", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "media", force: :cascade do |t|
    t.integer  "attachable_id",   limit: 4
    t.string   "attachable_type", limit: 255
    t.string   "key",             limit: 255
    t.string   "file_name",       limit: 255
    t.string   "file_type",       limit: 255
    t.integer  "file_size",       limit: 4
    t.binary   "file_data",       limit: 4294967295
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "media", ["attachable_id", "attachable_type"], name: "index_media_on_attachable_id_and_attachable_type", using: :btree

  create_table "memberships", force: :cascade do |t|
    t.integer  "user_id",        limit: 4
    t.integer  "group_id",       limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "level",          limit: 4, default: 1
    t.integer  "permissions",    limit: 4
    t.boolean  "receive_emails"
  end

  add_index "memberships", ["receive_emails"], name: "index_memberships_on_receive_emails", using: :btree

  create_table "pages", force: :cascade do |t|
    t.string   "category",   limit: 255
    t.string   "title",      limit: 255
    t.string   "language",   limit: 255
    t.text     "body",       limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug",       limit: 255
  end

  create_table "positions", force: :cascade do |t|
    t.text     "style",       limit: 65535
    t.decimal  "top",                       precision: 6, scale: 5, default: 0.0
    t.decimal  "left",                      precision: 6, scale: 5, default: 0.0
    t.decimal  "bottom",                    precision: 6, scale: 5, default: 0.0
    t.decimal  "right",                     precision: 6, scale: 5, default: 0.0
    t.integer  "field_id",    limit: 4
    t.integer  "template_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "screens", force: :cascade do |t|
    t.string   "name",                 limit: 255
    t.string   "location",             limit: 255
    t.boolean  "is_public"
    t.integer  "owner_id",             limit: 4
    t.string   "owner_type",           limit: 255
    t.integer  "template_id",          limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "width",                limit: 4
    t.integer  "height",               limit: 4
    t.datetime "frontend_updated_at"
    t.string   "authentication_token", limit: 255
    t.string   "time_zone",            limit: 255
  end

  create_table "submissions", force: :cascade do |t|
    t.integer  "content_id",        limit: 4
    t.integer  "feed_id",           limit: 4
    t.boolean  "moderation_flag"
    t.integer  "moderator_id",      limit: 4
    t.integer  "duration",          limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "moderation_reason", limit: 65535
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer  "feed_id",    limit: 4
    t.integer  "field_id",   limit: 4
    t.integer  "screen_id",  limit: 4
    t.integer  "weight",     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "templates", force: :cascade do |t|
    t.string   "name",            limit: 255
    t.string   "author",          limit: 255
    t.boolean  "is_hidden",                   default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "original_width",  limit: 4
    t.integer  "original_height", limit: 4
    t.integer  "owner_id",        limit: 4
    t.string   "owner_type",      limit: 255
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                            limit: 255, default: "",    null: false
    t.string   "encrypted_password",               limit: 255, default: "",    null: false
    t.string   "reset_password_token",             limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "first_name",                       limit: 255
    t.string   "last_name",                        limit: 255
    t.string   "locale",                           limit: 255
    t.boolean  "is_admin",                                     default: false
    t.boolean  "receive_moderation_notifications"
    t.string   "time_zone",                        limit: 255
    t.string   "confirmation_token",               limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email",                limit: 255
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
