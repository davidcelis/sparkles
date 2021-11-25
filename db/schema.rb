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

ActiveRecord::Schema.define(version: 2021_11_25_174317) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "channels", force: :cascade do |t|
    t.string "slack_team_id", null: false
    t.string "slack_id", null: false
    t.string "name", null: false
    t.boolean "private", default: false, null: false
    t.boolean "archived", default: false, null: false
    t.boolean "deleted", default: false, null: false
    t.datetime "created_at", precision: 6, default: -> { "now()" }, null: false
    t.datetime "updated_at", precision: 6, default: -> { "now()" }, null: false
    t.boolean "shared", default: false, null: false
    t.boolean "read_only", default: false, null: false
    t.index ["slack_team_id", "slack_id"], name: "index_channels_on_slack_team_id_and_slack_id", unique: true
  end

  create_table "sparkles", force: :cascade do |t|
    t.string "reason"
    t.string "permalink"
    t.datetime "created_at", precision: 6, default: -> { "now()" }, null: false
    t.datetime "updated_at", precision: 6, default: -> { "now()" }, null: false
    t.bigint "sparklee_id", null: false
    t.bigint "sparkler_id", null: false
    t.bigint "channel_id", null: false
    t.index ["channel_id"], name: "index_sparkles_on_channel_id"
    t.index ["sparklee_id"], name: "index_sparkles_on_sparklee_id"
    t.index ["sparkler_id"], name: "index_sparkles_on_sparkler_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "slack_id", null: false
    t.string "name", null: false
    t.string "slack_token", null: false
    t.string "sparklebot_id", null: false
    t.string "icon_url"
    t.datetime "created_at", precision: 6, default: -> { "now()" }, null: false
    t.datetime "updated_at", precision: 6, default: -> { "now()" }, null: false
    t.string "slack_feed_channel_id"
    t.boolean "leaderboard_enabled", default: true, null: false
    t.boolean "uninstalled", default: false, null: false
    t.index ["slack_id"], name: "index_teams_on_slack_id", unique: true
    t.index ["uninstalled"], name: "index_teams_on_uninstalled"
  end

  create_table "users", force: :cascade do |t|
    t.string "slack_team_id", null: false
    t.string "slack_id", null: false
    t.string "name", null: false
    t.string "username"
    t.string "image_url"
    t.boolean "deactivated", default: false, null: false
    t.integer "sparkles_count", default: 0, null: false
    t.datetime "created_at", precision: 6, default: -> { "now()" }, null: false
    t.datetime "updated_at", precision: 6, default: -> { "now()" }, null: false
    t.boolean "team_admin", default: false, null: false
    t.boolean "leaderboard_enabled", default: true, null: false
    t.index ["slack_team_id", "slack_id"], name: "index_users_on_slack_team_id_and_slack_id", unique: true
  end

end
