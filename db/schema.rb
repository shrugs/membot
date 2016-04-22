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

ActiveRecord::Schema.define(version: 20160422054528) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "conversations", force: :cascade do |t|
    t.string   "facebook_user_id"
    t.string   "email"
    t.string   "access_token"
    t.string   "token_type"
    t.integer  "expires_in"
    t.string   "refresh_token"
    t.string   "scope"
    t.integer  "memrise_id"
    t.string   "memrise_username"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.string   "state",            null: false
    t.string   "active_course_id"
    t.integer  "level_id"
  end

  add_index "conversations", ["facebook_user_id"], name: "index_conversations_on_facebook_user_id", using: :btree
  add_index "conversations", ["level_id"], name: "index_conversations_on_level_id", using: :btree

  create_table "levels", id: :integer, force: :cascade do |t|
    t.integer  "pool_id"
    t.string   "title"
    t.integer  "column_a"
    t.integer  "column_b"
    t.integer  "index"
    t.integer  "kind"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "levels", ["id"], name: "index_levels_on_id", using: :btree

  create_table "mems", id: :integer, force: :cascade do |t|
    t.integer "thing_id"
    t.string  "text"
    t.string  "image"
    t.string  "author_username"
  end

  add_index "mems", ["id"], name: "index_mems_on_id", using: :btree
  add_index "mems", ["thing_id"], name: "index_mems_on_thing_id", using: :btree

  create_table "questions", force: :cascade do |t|
    t.integer  "thing_id"
    t.integer  "conversation_id"
    t.string   "box_template"
    t.string   "given_answer"
    t.integer  "update_scheduling"
    t.integer  "score"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "questions", ["conversation_id"], name: "index_questions_on_conversation_id", using: :btree
  add_index "questions", ["thing_id"], name: "index_questions_on_thing_id", using: :btree

  create_table "thing_users", force: :cascade do |t|
    t.integer "thing_id"
    t.integer "conversation_id"
    t.integer "level_id"
    t.integer "score",           default: 0
  end

  add_index "thing_users", ["conversation_id"], name: "index_thing_users_on_conversation_id", using: :btree
  add_index "thing_users", ["level_id"], name: "index_thing_users_on_level_id", using: :btree
  add_index "thing_users", ["thing_id"], name: "index_thing_users_on_thing_id", using: :btree

  create_table "things", id: :integer, force: :cascade do |t|
    t.hstore  "columns"
    t.integer "level_id"
  end

  add_index "things", ["id"], name: "index_things_on_id", using: :btree
  add_index "things", ["level_id"], name: "index_things_on_level_id", using: :btree

end
