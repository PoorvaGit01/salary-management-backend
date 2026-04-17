class Employee < ApplicationRecord
  MAX_NAME_LENGTH = 100
  MAX_TITLE_LENGTH = 255
  MAX_EMAIL_LENGTH = 254
  MAX_SALARY = 999_999_999_999.99

  enum :employment_status, { active: 0, on_leave: 1, terminated: 2 }, default: :active

  before_validation :normalize_attributes

  validates :first_name, :last_name, presence: true, length: { maximum: MAX_NAME_LENGTH }
  validates :job_title, presence: true, length: { maximum: MAX_TITLE_LENGTH }
  validates :department, length: { maximum: MAX_TITLE_LENGTH }, allow_blank: true

  validates :country, presence: true, length: { is: 2 }, format: { with: /\A[A-Z]{2}\z/, message: "must be a 2-letter ISO country code" }
  validates :currency, presence: true, length: { is: 3 }, format: { with: /\A[A-Z]{3}\z/, message: "must be a 3-letter ISO currency code" }

  validates :salary, numericality: {
    greater_than: 0,
    less_than_or_equal_to: MAX_SALARY
  }

  validates :email,
            uniqueness: { allow_blank: true },
            length: { maximum: MAX_EMAIL_LENGTH },
            format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }

  validates :employee_number,
            uniqueness: { allow_blank: true },
            length: { maximum: 64 },
            format: {
              with: /\A[A-Z0-9]+(?:-[A-Z0-9]+)*\z/,
              allow_blank: true,
              message: "may only use letters, digits, and hyphen-separated segments (e.g. ENG-001)"
            }

  validate :hired_on_not_in_future
  validate :hired_on_not_before_1900

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

  def hired_on_not_in_future
    return if hired_on.blank?

    if hired_on > Date.current
      errors.add(:hired_on, "cannot be in the future")
    end
  end

  def hired_on_not_before_1900
    return if hired_on.blank?

    if hired_on < Date.new(1900, 1, 1)
      errors.add(:hired_on, "must be on or after 1900-01-01")
    end
  end
end
