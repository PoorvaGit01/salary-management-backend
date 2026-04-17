class CreateEmployees < ActiveRecord::Migration[8.1]
  def change
    create_table :employees do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :job_title, null: false
      t.string :country, null: false, limit: 2
      t.decimal :salary, precision: 14, scale: 2, null: false
      t.string :email
      t.string :department
      t.date :hired_on
      t.integer :employment_status, null: false, default: 0
      t.string :currency, null: false, limit: 3, default: "USD"
      t.string :employee_number

      t.timestamps
    end

    add_index :employees, :email, unique: true, where: "email IS NOT NULL"
    add_index :employees, :employee_number, unique: true, where: "employee_number IS NOT NULL"
    add_index :employees, :country
  end
end
