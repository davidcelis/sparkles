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

ActiveRecord::Schema.define(version: 2021_10_24_031447) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "channels", id: :string, force: :cascade do |t|
    t.string "team_id", null: false
    t.string "name", null: false
    t.boolean "private", default: false, null: false
    t.boolean "archived", default: false, null: false
    t.boolean "deleted", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["id", "team_id"], name: "index_channels_on_id_and_team_id", unique: true
    t.index ["team_id"], name: "index_channels_on_team_id"
  end

  create_table "sparkles", force: :cascade do |t|
    t.string "sparklee_id", null: false
    t.string "sparkler_id", null: false
    t.string "channel_id", null: false
    t.string "reason"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["sparklee_id"], name: "index_sparkles_on_sparklee_id"
    t.index ["sparkler_id"], name: "index_sparkles_on_sparkler_id"
  end

  create_table "teams", id: :string, force: :cascade do |t|
    t.string "slack_token", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "name"
    t.string "icon_url"
  end

  create_table "users", id: :string, force: :cascade do |t|
    t.string "team_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "slack_token"
    t.string "name"
    t.string "username"
    t.string "image_url"
    t.boolean "deactivated", default: false, null: false
    t.index ["id", "team_id"], name: "index_users_on_id_and_team_id", unique: true
    t.index ["team_id"], name: "index_users_on_team_id"
  end

  add_foreign_key "channels", "teams"
  add_foreign_key "sparkles", "channels"
  add_foreign_key "sparkles", "users", column: "sparklee_id"
  add_foreign_key "sparkles", "users", column: "sparkler_id"
  add_foreign_key "users", "teams"
end
