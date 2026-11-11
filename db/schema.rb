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

ActiveRecord::Schema[8.1].define(version: 2026_11_11_114527) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "ap_objects", force: :cascade do |t|
    t.string "uri", null: false
    t.boolean "public"
    t.string "media_urls", array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uri"], name: "index_ap_objects_on_uri", unique: true
  end

  create_table "fasp_base_admin_users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_fasp_base_admin_users_on_email", unique: true
  end

  create_table "fasp_base_invitation_codes", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_fasp_base_invitation_codes_on_code", unique: true
  end

  create_table "fasp_base_servers", force: :cascade do |t|
    t.string "base_url", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "fasp_private_key_pem", null: false
    t.string "fasp_remote_id"
    t.string "public_key_pem"
    t.string "registration_completion_uri"
    t.json "enabled_capabilities"
    t.string "namespace", null: false
    t.index ["base_url"], name: "index_fasp_base_servers_on_base_url", unique: true
    t.index ["namespace"], name: "index_fasp_base_servers_on_namespace", unique: true
    t.index ["user_id"], name: "index_fasp_base_servers_on_user_id"
  end

  create_table "fasp_base_settings", force: :cascade do |t|
    t.string "name", null: false
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_fasp_base_settings_on_name", unique: true
  end

  create_table "fasp_base_users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: true, null: false
    t.index ["email"], name: "index_fasp_base_users_on_email", unique: true
  end

  create_table "media_files", force: :cascade do |t|
    t.integer "file_size", null: false
    t.string "sha512", null: false
    t.string "content_type", null: false
    t.integer "width"
    t.integer "height"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sha512"], name: "index_media_files_on_sha512", unique: true
  end

  create_table "storage_requests", force: :cascade do |t|
    t.bigint "fasp_base_server_id", null: false
    t.bigint "ap_object_id", null: false
    t.bigint "media_file_id"
    t.string "file_url", null: false
    t.integer "state", default: 0, null: false
    t.string "rejection_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ap_object_id"], name: "index_storage_requests_on_ap_object_id"
    t.index ["fasp_base_server_id"], name: "index_storage_requests_on_fasp_base_server_id"
    t.index ["file_url"], name: "index_storage_requests_on_file_url"
    t.index ["media_file_id"], name: "index_storage_requests_on_media_file_id"
  end

  add_foreign_key "fasp_base_servers", "fasp_base_users", column: "user_id"
  add_foreign_key "storage_requests", "ap_objects"
  add_foreign_key "storage_requests", "fasp_base_servers"
  add_foreign_key "storage_requests", "media_files"
end
