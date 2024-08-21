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

ActiveRecord::Schema[7.1].define(version: 2024_08_21_201527) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_stat_statements"
  enable_extension "plpgsql"
  enable_extension "vector"

  create_table "api_tokens", force: :cascade do |t|
    t.boolean "active"
    t.text "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.bigint "user_id", null: false
    t.boolean "shown_once"
    t.datetime "last_used"
    t.index ["user_id"], name: "index_api_tokens_on_user_id"
  end

  create_table "assistants", force: :cascade do |t|
    t.text "user_prompt"
    t.text "llm_prompt"
    t.text "libraries"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "chats", force: :cascade do |t|
    t.bigint "assistant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assistant_id"], name: "index_chats_on_assistant_id"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "documents", force: :cascade do |t|
    t.text "document"
    t.string "url"
    t.integer "length"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.vector "embedding", limit: 1536
    t.string "title"
    t.string "check_hash"
    t.integer "token_count"
    t.bigint "library_id"
    t.bigint "user_id"
    t.boolean "disabled"
    t.string "external_id"
    t.boolean "enabled", default: true
    t.integer "questions_count", default: 0, null: false
    t.index ["created_at"], name: "index_documents_on_created_at"
    t.index ["embedding"], name: "index_documents_on_embedding", opclass: :vector_l2_ops, using: :hnsw
    t.index ["external_id"], name: "index_documents_on_external_id", unique: true
    t.index ["library_id"], name: "index_documents_on_library_id"
    t.index ["questions_count"], name: "index_documents_on_questions_count"
    t.index ["user_id"], name: "index_documents_on_user_id"
  end

  create_table "documents_questions", id: false, force: :cascade do |t|
    t.bigint "document_id", null: false
    t.bigint "question_id", null: false
  end

  create_table "libraries", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.integer "documents_count", default: 0, null: false
    t.string "source_url"
    t.index ["user_id"], name: "index_libraries_on_user_id"
  end

  create_table "library_users", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "library_id", null: false
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["library_id"], name: "index_library_users_on_library_id"
    t.index ["user_id", "library_id"], name: "index_library_users_on_user_id_and_library_id", unique: true
    t.index ["user_id"], name: "index_library_users_on_user_id"
  end

  create_table "questions", force: :cascade do |t|
    t.text "question"
    t.text "answer"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "library_id"
    t.text "prompt"
    t.bigint "user_id"
    t.boolean "able_to_answer", default: true
    t.float "generation_time"
    t.integer "status", default: 2, null: false
    t.vector "embedding", limit: 1536
    t.string "source_url"
    t.string "library_ids_included", default: [], array: true
    t.datetime "generated_at"
    t.index ["created_at"], name: "index_questions_on_created_at"
    t.index ["embedding"], name: "index_questions_on_embedding", opclass: :vector_cosine_ops, using: :ivfflat
    t.index ["library_id"], name: "index_questions_on_library_id"
    t.index ["user_id"], name: "index_questions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.boolean "admin"
    t.datetime "last_login"
  end

  create_table "votes", force: :cascade do |t|
    t.string "votable_type"
    t.bigint "votable_id"
    t.string "voter_type"
    t.bigint "voter_id"
    t.boolean "vote_flag"
    t.string "vote_scope"
    t.integer "vote_weight"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["votable_id", "votable_type", "vote_scope"], name: "index_votes_on_votable_id_and_votable_type_and_vote_scope"
    t.index ["votable_type", "votable_id"], name: "index_votes_on_votable"
    t.index ["voter_id", "voter_type", "vote_scope"], name: "index_votes_on_voter_id_and_voter_type_and_vote_scope"
    t.index ["voter_type", "voter_id"], name: "index_votes_on_voter"
  end

  add_foreign_key "api_tokens", "users"
  add_foreign_key "chats", "assistants"
  add_foreign_key "documents", "libraries"
  add_foreign_key "documents", "users"
  add_foreign_key "libraries", "users"
  add_foreign_key "library_users", "libraries"
  add_foreign_key "library_users", "users"
  add_foreign_key "questions", "libraries"
  add_foreign_key "questions", "users"
end
