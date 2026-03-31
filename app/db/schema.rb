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

ActiveRecord::Schema[8.1].define(version: 2026_03_27_030204) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vector"

  create_table "archetype_impacts", force: :cascade do |t|
    t.bigint "archetype_id", null: false
    t.datetime "created_at", null: false
    t.string "impact_kind"
    t.float "impact_score"
    t.bigint "patch_change_id", null: false
    t.text "reasoning"
    t.datetime "updated_at", null: false
    t.index ["archetype_id"], name: "index_archetype_impacts_on_archetype_id"
    t.index ["patch_change_id"], name: "index_archetype_impacts_on_patch_change_id"
  end

  create_table "archetypes", force: :cascade do |t|
    t.string "ascendancy_name"
    t.string "class_name"
    t.jsonb "core_mechanics", default: []
    t.datetime "created_at", null: false
    t.jsonb "defense_tags", default: []
    t.text "failure_modes"
    t.text "leveling_notes"
    t.string "name"
    t.jsonb "offense_tags", default: []
    t.string "primary_skill"
    t.datetime "updated_at", null: false
  end

  create_table "character_snapshots", force: :cascade do |t|
    t.string "ascendancy_name"
    t.string "class_name"
    t.jsonb "constraints", default: {}
    t.datetime "created_at", null: false
    t.jsonb "defenses", default: {}
    t.jsonb "gear", default: {}
    t.integer "level"
    t.string "name"
    t.jsonb "passives", default: {}
    t.jsonb "skills", default: {}
    t.jsonb "stats", default: {}
    t.datetime "updated_at", null: false
  end

  create_table "patch_changes", force: :cascade do |t|
    t.text "after_text"
    t.text "before_text"
    t.string "change_type"
    t.float "confidence"
    t.datetime "created_at", null: false
    t.string "entity_name"
    t.string "entity_type"
    t.jsonb "numeric_data", default: {}
    t.bigint "patch_document_id", null: false
    t.text "summary"
    t.jsonb "tags", default: []
    t.datetime "updated_at", null: false
    t.index ["patch_document_id"], name: "index_patch_changes_on_patch_document_id"
  end

  create_table "patch_documents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "document_type"
    t.jsonb "metadata", default: {}
    t.datetime "published_at"
    t.text "raw_text"
    t.string "source_url"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "version"
  end

  create_table "recommendation_runs", force: :cascade do |t|
    t.bigint "character_snapshot_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "input_payload", default: {}
    t.string "mode"
    t.jsonb "output_payload", default: {}
    t.datetime "updated_at", null: false
    t.index ["character_snapshot_id"], name: "index_recommendation_runs_on_character_snapshot_id"
  end

  add_foreign_key "archetype_impacts", "archetypes"
  add_foreign_key "archetype_impacts", "patch_changes"
  add_foreign_key "patch_changes", "patch_documents"
  add_foreign_key "recommendation_runs", "character_snapshots"
end
