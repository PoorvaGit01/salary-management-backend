require "test_helper"

class EmployeeTest < ActiveSupport::TestCase
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
    assert_not employee.valid?
    assert_includes employee.errors[:first_name], "can't be blank"
    assert_includes employee.errors[:last_name], "can't be blank"
    assert_includes employee.errors[:job_title], "can't be blank"
    assert_includes employee.errors[:country], "can't be blank"
    assert employee.errors[:salary].any?
  end

  test "normalizes country and currency" do
    employee = Employee.new(
      first_name: "A",
      last_name: "B",
      job_title: "Role",
      country: "us",
      salary: 50_000,
      currency: "usd"
    )
    employee.valid?
    assert_equal "US", employee.country
    assert_equal "USD", employee.currency
  end
end
