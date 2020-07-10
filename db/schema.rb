# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_06_12_003235) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "chatboxes", force: :cascade do |t|
    t.integer "room_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "games", force: :cascade do |t|
    t.integer "room_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "messages", force: :cascade do |t|
    t.string "payload"
    t.integer "user_id"
    t.integer "chatbox_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "rooms", force: :cascade do |t|
    t.string "name"
    t.string "password_digest"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "rounds", force: :cascade do |t|
    t.integer "game_id"
    t.integer "phase", default: 0
    t.integer "turn_count", default: 0
    t.integer "no_players_for_phase", default: 0
    t.integer "small_blind_index", default: 0
    t.integer "turn_index", default: 0
    t.integer "pot", default: 0
    t.integer "highest_bet_for_phase", default: 0
    t.string "community_cards"
    t.text "status", default: [], array: true
    t.boolean "is_playing", default: false
    t.boolean "all_in", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "username"
    t.string "email"
    t.string "password_digest"
    t.integer "room_id"
    t.integer "connect_account_id"
    t.integer "game_id"
    t.integer "round_id"
    t.boolean "playing"
    t.integer "round_bet"
    t.integer "chips", default: 0
    t.string "cards"
    t.boolean "dealer", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

end
