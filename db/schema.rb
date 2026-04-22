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

ActiveRecord::Schema[8.1].define(version: 2026_04_22_120041) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "employees", force: :cascade do |t|
    t.string "country", limit: 2, null: false
    t.datetime "created_at", null: false
    t.string "currency", limit: 3, default: "USD", null: false
    t.string "department"
    t.string "email"
    t.string "employee_number"
    t.integer "employment_status", default: 0, null: false
    t.string "first_name", null: false
    t.date "hired_on"
    t.string "job_title", null: false
    t.string "last_name", null: false
    t.decimal "salary", precision: 14, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["country", "job_title"], name: "index_employees_on_country_and_job_title"
    t.index ["country"], name: "index_employees_on_country"
    t.index ["email"], name: "index_employees_on_email", unique: true, where: "(email IS NOT NULL)"
    t.index ["employee_number"], name: "index_employees_on_employee_number", unique: true, where: "(employee_number IS NOT NULL)"
  end
end
