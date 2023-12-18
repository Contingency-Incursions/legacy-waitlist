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

ActiveRecord::Schema[7.1].define(version: 2023_12_18_043735) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "access_token", primary_key: "character_id", id: :bigint, default: nil, force: :cascade do |t|
    t.string "access_token", limit: 2048, null: false
    t.bigint "expires", null: false
    t.string "scopes", limit: 1024, null: false
  end

  create_table "admin", primary_key: "character_id", id: :bigint, default: nil, force: :cascade do |t|
    t.string "role", limit: 64, null: false
    t.bigint "granted_at", null: false
    t.bigint "granted_by_id", null: false
  end

  create_table "alliance", id: :bigint, default: nil, force: :cascade do |t|
    t.text "name", null: false
  end

  create_table "alt_character", primary_key: ["account_id", "alt_id"], force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "alt_id", null: false
  end

  create_table "announcement", id: :bigint, default: nil, force: :cascade do |t|
    t.string "message", limit: 512, null: false
    t.boolean "is_alert", default: false, null: false
    t.text "pages"
    t.bigint "created_by_id", null: false
    t.bigint "created_at", null: false
    t.bigint "revoked_by_id"
    t.bigint "revoked_at"
  end

  create_table "badge", id: :bigint, default: nil, force: :cascade do |t|
    t.string "name", limit: 64, null: false
    t.bigint "exclude_badge_id"

    t.unique_constraint ["name"], name: "badge_name_key"
  end

  create_table "badge_assignment", id: false, force: :cascade do |t|
    t.bigint "characterid", null: false
    t.bigint "badgeid", null: false
    t.bigint "grantedbyid"
    t.bigint "grantedat", null: false
  end

  create_table "ban", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "entity_id", null: false
    t.string "entity_name", limit: 64
    t.string "entity_type", limit: 16, null: false
    t.bigint "issued_at", null: false
    t.bigint "issued_by", null: false
    t.string "public_reason", limit: 512
    t.string "reason", limit: 512, null: false
    t.bigint "revoked_at"
    t.bigint "revoked_by"
    t.check_constraint "entity_type::text = ANY (ARRAY['Account'::character varying, 'Character'::character varying, 'Corporation'::character varying, 'Alliance'::character varying]::text[])", name: "ban_entity_type_check"
  end

  create_table "character", id: :bigint, default: nil, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.bigint "corporation_id"
    t.bigint "last_seen", default: -> { "date_part('epoch'::text, now())" }, null: false
    t.datetime "skills_last_checked"
  end

  create_table "character_note", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "character_id", null: false
    t.bigint "author_id", null: false
    t.text "note", null: false
    t.bigint "logged_at", null: false
  end

  create_table "corporation", id: :bigint, default: nil, force: :cascade do |t|
    t.text "name", null: false
    t.bigint "alliance_id"
    t.bigint "updated_at", null: false
  end

  create_table "dgm_type_attributes", primary_key: ["typeID", "attributeID"], force: :cascade do |t|
    t.integer "typeID", null: false
    t.integer "attributeID", null: false
    t.integer "valueInt"
    t.float "valueFloat"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "dgm_type_effects", primary_key: ["typeID", "effectID"], force: :cascade do |t|
    t.integer "typeID", null: false
    t.integer "effectID", null: false
    t.boolean "isDefault"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "fit_history", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "character_id", null: false
    t.bigint "fit_id", null: false
    t.bigint "implant_set_id", null: false
    t.bigint "logged_at", null: false
  end

  create_table "fitting", id: :bigint, default: nil, force: :cascade do |t|
    t.string "dna", limit: 1024, null: false
    t.integer "hull", null: false

    t.unique_constraint ["dna"], name: "fitting_dna_key"
  end

  create_table "fleet", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "boss_id", null: false
    t.bigint "boss_system_id"
    t.bigint "max_size", null: false
    t.boolean "visible", default: false, null: false
    t.bigint "error_count", default: 0, null: false
  end

  create_table "fleet_activity", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "character_id", null: false
    t.bigint "fleet_id", null: false
    t.bigint "first_seen", null: false
    t.bigint "last_seen", null: false
    t.integer "hull", null: false
    t.boolean "has_left", null: false
    t.boolean "is_boss", null: false
  end

  create_table "fleet_squad", primary_key: ["fleet_id", "category"], force: :cascade do |t|
    t.bigint "fleet_id", null: false
    t.string "category", limit: 10, null: false
    t.bigint "wing_id", null: false
    t.bigint "squad_id", null: false
  end

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.jsonb "serialized_properties"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_discard"
    t.text "callback_queue_name"
    t.integer "callback_priority"
    t.datetime "enqueued_at"
    t.datetime "discarded_at"
    t.datetime "finished_at"
  end

  create_table "good_job_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id", null: false
    t.text "job_class"
    t.text "queue_name"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.text "error"
    t.integer "error_event", limit: 2
    t.index ["active_job_id", "created_at"], name: "index_good_job_executions_on_active_job_id_and_created_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "state"
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "key"
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "queue_name"
    t.integer "priority"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "performed_at"
    t.datetime "finished_at"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id"
    t.text "concurrency_key"
    t.text "cron_key"
    t.uuid "retried_good_job_id"
    t.datetime "cron_at"
    t.uuid "batch_id"
    t.uuid "batch_callback_id"
    t.boolean "is_discrete"
    t.integer "executions_count"
    t.text "job_class"
    t.integer "error_event", limit: 2
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["active_job_id"], name: "index_good_jobs_on_active_job_id"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at", unique: true
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at", where: "((retried_good_job_id IS NULL) AND (finished_at IS NOT NULL))"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "implant_set", id: :bigint, default: nil, force: :cascade do |t|
    t.string "implants", limit: 255, null: false

    t.unique_constraint ["implants"], name: "implant_set_implants_key"
  end

  create_table "inv_groups", id: false, force: :cascade do |t|
    t.integer "groupID"
    t.integer "categoryID"
    t.string "groupName"
    t.integer "iconID"
    t.boolean "useBasePrice"
    t.boolean "anchored"
    t.boolean "anchorable"
    t.boolean "fittableNonSingleton"
    t.boolean "published"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["categoryID"], name: "index_inv_groups_on_categoryID"
    t.index ["groupID"], name: "index_inv_groups_on_groupID", unique: true
  end

  create_table "inv_meta_types", id: false, force: :cascade do |t|
    t.integer "typeID"
    t.integer "parentTypeID"
    t.integer "metaGroupID"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["typeID"], name: "index_inv_meta_types_on_typeID", unique: true
  end

  create_table "inv_types", id: false, force: :cascade do |t|
    t.integer "typeID", null: false
    t.integer "groupID"
    t.string "typeName", limit: 100
    t.text "description"
    t.float "mass"
    t.float "volume"
    t.float "capacity"
    t.integer "portionSize"
    t.integer "raceID"
    t.decimal "basePrice", precision: 19, scale: 4
    t.boolean "published", default: true
    t.integer "marketGroupID"
    t.integer "iconID"
    t.integer "soundID"
    t.integer "graphicID"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["groupID"], name: "index_inv_types_on_groupID"
    t.index ["typeID"], name: "index_inv_types_on_typeID", unique: true
  end

  create_table "map_solar_systems", id: false, force: :cascade do |t|
    t.integer "regionID"
    t.integer "constellationID"
    t.integer "solarSystemID"
    t.string "solarSystemName"
    t.float "x"
    t.float "y"
    t.float "z"
    t.float "xMin"
    t.float "xMax"
    t.float "yMin"
    t.float "yMax"
    t.float "zMin"
    t.float "zMax"
    t.float "luminosity"
    t.boolean "border"
    t.boolean "fringe"
    t.boolean "corridor"
    t.boolean "hub"
    t.boolean "international"
    t.boolean "regional"
    t.boolean "constellation"
    t.float "security"
    t.integer "factionID"
    t.float "radius"
    t.integer "sunTypeID"
    t.string "securityClass"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["solarSystemID"], name: "index_map_solar_systems_on_solarSystemID", unique: true
  end

  create_table "refresh_token", primary_key: "character_id", id: :bigint, default: nil, force: :cascade do |t|
    t.string "refresh_token", limit: 255, null: false
    t.string "scopes", limit: 1024, null: false
  end

  create_table "role_mapping", id: :bigint, default: nil, force: :cascade do |t|
    t.string "waitlist_role", limit: 64, null: false
    t.string "dokuwiki_role", limit: 64, null: false

    t.unique_constraint ["waitlist_role"], name: "role_mapping_waitlist_role_key"
  end

  create_table "skill_current", primary_key: ["character_id", "skill_id"], force: :cascade do |t|
    t.bigint "character_id", null: false
    t.integer "skill_id", null: false
    t.integer "level", limit: 2, null: false
  end

  create_table "skill_history", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "character_id", null: false
    t.integer "skill_id", null: false
    t.integer "old_level", limit: 2, null: false
    t.integer "new_level", limit: 2, null: false
    t.bigint "logged_at", null: false
  end

  create_table "waitlist_entry", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "joined_at", null: false
  end

  create_table "waitlist_entry_fit", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "character_id", null: false
    t.bigint "entry_id", null: false
    t.bigint "fit_id", null: false
    t.bigint "implant_set_id", null: false
    t.string "tags", limit: 255, null: false
    t.string "category", limit: 10, null: false
    t.text "fit_analysis"
    t.text "review_comment"
    t.bigint "cached_time_in_fleet", null: false
    t.boolean "is_alt", null: false
    t.string "state", limit: 10, default: "pending", null: false
    t.check_constraint "state::text = ANY (ARRAY['pending'::character varying, 'approved'::character varying, 'rejected'::character varying]::text[])", name: "fit_state"
  end

  create_table "wiki_user", primary_key: "character_id", id: :bigint, default: nil, force: :cascade do |t|
    t.string "user", limit: 255, null: false
    t.string "hash", limit: 60, null: false
    t.string "mail", limit: 255, null: false

    t.unique_constraint ["mail"], name: "wiki_user_mail_key"
    t.unique_constraint ["user"], name: "wiki_user_user_key"
  end

  add_foreign_key "access_token", "character", name: "access_token_character_id"
  add_foreign_key "admin", "character", column: "granted_by_id", name: "admin_character"
  add_foreign_key "admin", "character", name: "character_role"
  add_foreign_key "alt_character", "character", column: "account_id", name: "alt_character_account_id"
  add_foreign_key "alt_character", "character", column: "alt_id", name: "alt_character_alt_id"
  add_foreign_key "announcement", "character", column: "created_by_id", name: "announcement_by"
  add_foreign_key "announcement", "character", column: "revoked_by_id", name: "announcement_revoked_by"
  add_foreign_key "badge", "badge", column: "exclude_badge_id", name: "exclude_badge", on_delete: :nullify
  add_foreign_key "badge_assignment", "badge", column: "badgeid", name: "badge_assignment_badgeid", on_delete: :cascade
  add_foreign_key "badge_assignment", "character", column: "characterid", name: "badge_assignment_characterid"
  add_foreign_key "badge_assignment", "character", column: "grantedbyid", name: "badge_assignment_grantedbyid"
  add_foreign_key "ban", "character", column: "issued_by", name: "issued_by"
  add_foreign_key "ban", "character", column: "revoked_by", name: "revoked_by"
  add_foreign_key "character", "corporation", name: "character_corporation"
  add_foreign_key "character_note", "character", column: "author_id", name: "character_note_author_id"
  add_foreign_key "character_note", "character", name: "character_note_character_id"
  add_foreign_key "corporation", "alliance", name: "alliance_id"
  add_foreign_key "fit_history", "character", name: "fit_history_character_id"
  add_foreign_key "fit_history", "fitting", column: "fit_id", name: "fit_history_fit_id"
  add_foreign_key "fit_history", "implant_set", name: "fit_history_implant_set_id"
  add_foreign_key "fleet", "character", column: "boss_id", name: "fleet_boss_id"
  add_foreign_key "fleet_activity", "character", name: "fleet_activity_character_id"
  add_foreign_key "fleet_squad", "fleet", name: "fleet_squad_fleet_id"
  add_foreign_key "refresh_token", "character", name: "refresh_token_character_id"
  add_foreign_key "skill_current", "character", name: "skill_current_character_id"
  add_foreign_key "skill_history", "character", name: "skill_history_character_id"
  add_foreign_key "waitlist_entry", "character", column: "account_id", name: "waitlist_entry_account_id"
  add_foreign_key "waitlist_entry_fit", "character", name: "waitlist_entry_fit_character_id"
  add_foreign_key "waitlist_entry_fit", "fitting", column: "fit_id", name: "waitlist_entry_fit_fit_id"
  add_foreign_key "waitlist_entry_fit", "implant_set", name: "waitlist_entry_fit_implant_set_id"
  add_foreign_key "waitlist_entry_fit", "waitlist_entry", column: "entry_id", name: "waitlist_entry_fit_entry_id"
  add_foreign_key "wiki_user", "character", name: "wiki_character"
end
