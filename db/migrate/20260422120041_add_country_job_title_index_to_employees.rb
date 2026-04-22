class AddCountryJobTitleIndexToEmployees < ActiveRecord::Migration[8.1]
  def change
    add_index :employees, [:country, :job_title]
  end
end
