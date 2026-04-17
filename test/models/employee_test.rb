require "test_helper"

class EmployeeTest < ActiveSupport::TestCase
  def valid_attributes
    {
      first_name: "Jane",
      last_name: "Doe",
      job_title: "Engineer",
      country: "US",
      salary: 75_000,
      currency: "USD"
    }
  end

  test "full_name joins first and last name" do
    employee = Employee.new(first_name: "Jane", last_name: "Doe")
    assert_equal "Jane Doe", employee.full_name
  end

  test "full_name omits blank parts" do
    employee = Employee.new(first_name: "", last_name: "Solo")
    assert_equal "Solo", employee.full_name
  end

  test "requires core attributes" do
    employee = Employee.new
    employee.currency = nil # schema default would otherwise pre-fill currency
    assert_not employee.valid?
    assert_includes employee.errors[:first_name], "can't be blank"
    assert_includes employee.errors[:last_name], "can't be blank"
    assert_includes employee.errors[:job_title], "can't be blank"
    assert_includes employee.errors[:country], "can't be blank"
    assert employee.errors[:salary].any?
    assert_includes employee.errors[:currency], "can't be blank"
  end

  test "first_name and last_name cannot exceed max length" do
    long = "a" * (Employee::MAX_NAME_LENGTH + 1)
    employee = Employee.new(valid_attributes.merge(first_name: long))
    assert_not employee.valid?
    assert_includes employee.errors[:first_name], "is too long (maximum is #{Employee::MAX_NAME_LENGTH} characters)"

    employee = Employee.new(valid_attributes.merge(last_name: long))
    assert_not employee.valid?
    assert_includes employee.errors[:last_name], "is too long (maximum is #{Employee::MAX_NAME_LENGTH} characters)"
  end

  test "job_title cannot exceed max length" do
    long = "a" * (Employee::MAX_TITLE_LENGTH + 1)
    employee = Employee.new(valid_attributes.merge(job_title: long))
    assert_not employee.valid?
    assert_includes employee.errors[:job_title], "is too long (maximum is #{Employee::MAX_TITLE_LENGTH} characters)"
  end

  test "department cannot exceed max length when present" do
    long = "a" * (Employee::MAX_TITLE_LENGTH + 1)
    employee = Employee.new(valid_attributes.merge(department: long))
    assert_not employee.valid?
    assert_includes employee.errors[:department], "is too long (maximum is #{Employee::MAX_TITLE_LENGTH} characters)"
  end

  test "country must be a 2-letter ISO code after normalization" do
    employee = Employee.new(valid_attributes.merge(country: "USA"))
    assert_not employee.valid?
    assert employee.errors[:country].any?

    employee = Employee.new(valid_attributes.merge(country: "1A"))
    assert_not employee.valid?
    assert employee.errors[:country].any?
  end

  test "currency must be a 3-letter ISO code after normalization" do
    employee = Employee.new(valid_attributes.merge(currency: "US"))
    assert_not employee.valid?
    assert employee.errors[:currency].any?

    employee = Employee.new(valid_attributes.merge(currency: "USDD"))
    assert_not employee.valid?
    assert employee.errors[:currency].any?
  end

  test "salary must be positive and not above maximum" do
    employee = Employee.new(valid_attributes.merge(salary: 0))
    assert_not employee.valid?
    assert_includes employee.errors[:salary], "must be greater than 0"

    employee = Employee.new(valid_attributes.merge(salary: -1))
    assert_not employee.valid?
    assert_includes employee.errors[:salary], "must be greater than 0"

    employee = Employee.new(valid_attributes.merge(salary: Employee::MAX_SALARY + 1))
    assert_not employee.valid?
    assert_includes employee.errors[:salary], "must be less than or equal to #{Employee::MAX_SALARY}"
  end

  test "email must be valid format and length when present" do
    employee = Employee.new(valid_attributes.merge(email: "not-an-email"))
    assert_not employee.valid?
    assert employee.errors[:email].any?

    employee = Employee.new(valid_attributes.merge(email: "#{'a' * Employee::MAX_EMAIL_LENGTH}@x.com"))
    assert_not employee.valid?
    assert_includes employee.errors[:email], "is too long (maximum is #{Employee::MAX_EMAIL_LENGTH} characters)"
  end

  test "email must be unique ignoring case and surrounding space" do
    alice = employees(:alice)
    employee = Employee.new(valid_attributes.merge(email: "  #{alice.email.upcase} "))
    assert_not employee.valid?
    assert_includes employee.errors[:email], "has already been taken"
  end

  test "employee_number must match pattern and max length when present" do
    employee = Employee.new(valid_attributes.merge(employee_number: "bad id!"))
    assert_not employee.valid?
    assert employee.errors[:employee_number].any?

    employee = Employee.new(valid_attributes.merge(employee_number: "A" * (Employee::MAX_EMPLOYEE_NUMBER_LENGTH + 1)))
    assert_not employee.valid?
    assert_includes employee.errors[:employee_number], "is too long (maximum is #{Employee::MAX_EMPLOYEE_NUMBER_LENGTH} characters)"
  end

  test "employee_number must be unique when present" do
    alice = employees(:alice)
    employee = Employee.new(valid_attributes.merge(employee_number: alice.employee_number))
    assert_not employee.valid?
    assert_includes employee.errors[:employee_number], "has already been taken"
  end

  test "employee_number is normalized to uppercase" do
    employee = Employee.new(valid_attributes.merge(employee_number: "eng-099"))
    employee.valid?
    assert_equal "ENG-099", employee.employee_number
  end

  test "hired_on cannot be in the future" do
    employee = Employee.new(valid_attributes.merge(hired_on: Date.current + 1.day))
    assert_not employee.valid?
    assert_includes employee.errors[:hired_on], "cannot be in the future"
  end

  test "hired_on cannot be before 1900" do
    employee = Employee.new(valid_attributes.merge(hired_on: Date.new(1899, 12, 31)))
    assert_not employee.valid?
    assert_includes employee.errors[:hired_on], "must be on or after 1900-01-01"
  end

  test "hired_on may be today or omitted" do
    employee = Employee.new(valid_attributes.merge(hired_on: Date.current))
    assert employee.valid?

    employee = Employee.new(valid_attributes.merge(hired_on: nil))
    assert employee.valid?
  end

  test "normalizes country and currency" do
    employee = Employee.new(
      valid_attributes.merge(
        country: "us",
        currency: "usd"
      )
    )
    employee.valid?
    assert_equal "US", employee.country
    assert_equal "USD", employee.currency
  end

  test "strips leading and trailing whitespace from names and job title" do
    employee = Employee.new(
      valid_attributes.merge(
        first_name: "  Jane ",
        last_name: " Doe ",
        job_title: " Lead "
      )
    )
    employee.valid?
    assert_equal "Jane", employee.first_name
    assert_equal "Doe", employee.last_name
    assert_equal "Lead", employee.job_title
  end
end
