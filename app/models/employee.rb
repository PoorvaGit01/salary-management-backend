class Employee < ApplicationRecord
  enum :employment_status, { active: 0, on_leave: 1, terminated: 2 }, default: :active

  before_validation :normalize_country_and_currency

  validates :first_name, :last_name, :job_title, presence: true
  validates :country, presence: true, format: { with: /\A[A-Z]{2}\z/, message: "must be a 2-letter ISO country code" }
  validates :currency, presence: true, format: { with: /\A[A-Z]{3}\z/, message: "must be a 3-letter ISO currency code" }
  validates :salary, numericality: { greater_than: 0 }
  validates :email, uniqueness: { allow_blank: true }, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
  validates :employee_number, uniqueness: { allow_blank: true }

  def full_name
    [ first_name, last_name ].map(&:presence).compact.join(" ")
  end

  private

  def normalize_country_and_currency
    self.country = country.to_s.strip.upcase if country.present?
    self.currency = currency.to_s.strip.upcase if currency.present?
  end
end
