# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_11_15_035316) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "contents", force: :cascade do |t|
    t.json "config"
    t.datetime "created_at", null: false
    t.integer "duration"
    t.datetime "end_time"
    t.string "name"
    t.datetime "start_time"
    t.text "text"
    t.string "type"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_contents_on_user_id"
  end

  create_table "feeds", force: :cascade do |t|
    t.json "config"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.string "type"
    t.datetime "updated_at", null: false
  end

  create_table "fields", force: :cascade do |t|
    t.text "alt_names"
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_groups_on_name", unique: true
  end

  create_table "memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "group_id", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["group_id"], name: "index_memberships_on_group_id"
    t.index ["user_id", "group_id"], name: "index_memberships_on_user_id_and_group_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "positions", force: :cascade do |t|
    t.decimal "bottom"
    t.datetime "created_at", null: false
    t.integer "field_id", null: false
    t.decimal "left"
    t.decimal "right"
    t.text "style"
    t.integer "template_id", null: false
    t.decimal "top"
    t.datetime "updated_at", null: false
    t.index ["field_id"], name: "index_positions_on_field_id"
    t.index ["template_id"], name: "index_positions_on_template_id"
  end

  create_table "screens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "group_id", null: false
    t.string "name"
    t.integer "template_id", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_screens_on_group_id"
    t.index ["template_id"], name: "index_screens_on_template_id"
  end

  create_table "settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.string "value_type"
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "submissions", force: :cascade do |t|
    t.integer "content_id", null: false
    t.datetime "created_at", null: false
    t.integer "feed_id", null: false
    t.datetime "updated_at", null: false
    t.index ["content_id"], name: "index_submissions_on_content_id"
    t.index ["feed_id"], name: "index_submissions_on_feed_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "feed_id", null: false
    t.integer "field_id", null: false
    t.integer "screen_id", null: false
    t.datetime "updated_at", null: false
    t.index ["feed_id"], name: "index_subscriptions_on_feed_id"
    t.index ["field_id"], name: "index_subscriptions_on_field_id"
    t.index ["screen_id"], name: "index_subscriptions_on_screen_id"
  end

  create_table "templates", force: :cascade do |t|
    t.string "author"
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.boolean "is_system_user"
    t.string "last_name"
    t.string "provider"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "contents", "users"
  add_foreign_key "memberships", "groups"
  add_foreign_key "memberships", "users"
  add_foreign_key "positions", "fields"
  add_foreign_key "positions", "templates"
  add_foreign_key "screens", "groups"
  add_foreign_key "screens", "templates"
  add_foreign_key "submissions", "contents"
  add_foreign_key "submissions", "feeds"
  add_foreign_key "subscriptions", "feeds"
  add_foreign_key "subscriptions", "fields"
  add_foreign_key "subscriptions", "screens"
end
