class Employee < ApplicationRecord
  MAX_NAME_LENGTH = 100
  MAX_TITLE_LENGTH = 255
  MAX_EMAIL_LENGTH = 254
  MAX_EMPLOYEE_NUMBER_LENGTH = 64
  MAX_SALARY = 999_999_999_999.99

  enum :employment_status, { active: 0, on_leave: 1, terminated: 2 }, default: :active

  include EmployeeValidations

  before_validation :normalize_attributes

  def full_name
    [ first_name, last_name ].map(&:presence).compact.join(" ")
  end

  private

  def normalize_attributes
    %i[first_name last_name job_title].each do |attr|
      value = self[attr]
      self[attr] = value.to_s.strip if value.present?
    end

    self.department = department.to_s.strip.presence
    self.email = email.to_s.strip.downcase.presence
    self.employee_number = employee_number.to_s.strip.upcase.presence
    self.country = country.to_s.strip.upcase if country.present?
    self.currency = currency.to_s.strip.upcase if currency.present?
  end
end
