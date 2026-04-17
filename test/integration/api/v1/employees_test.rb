require "test_helper"

module Api
  module V1
    class EmployeesTest < ActionDispatch::IntegrationTest
      setup do
        @employee = employees(:alice)
      end

      test "GET index returns employees as JSON with full_name and meta" do
        get api_v1_employees_path, as: :json
        assert_response :success
        body = JSON.parse(response.body)
        assert_kind_of Array, body["employees"]
        assert_kind_of Hash, body["meta"]
        assert_equal 2, body["meta"]["total_count"]
        assert_equal 1, body["meta"]["page"]
        assert_equal 25, body["meta"]["per_page"]
        record = body["employees"].find { |row| row["id"] == @employee.id }
        assert_equal "Alice", record["first_name"]
        assert_equal "Anderson", record["last_name"]
        assert_equal "Alice Anderson", record["full_name"]
      end

      test "GET index paginates" do
        get api_v1_employees_path, params: { page: 1, per_page: 1 }, as: :json
        assert_response :success
        body = JSON.parse(response.body)
        assert_equal 1, body["employees"].size
        assert_equal 2, body["meta"]["total_count"]
        assert_equal 2, body["meta"]["total_pages"]
      end

      test "GET index filters by search query" do
        get api_v1_employees_path, params: { q: "alice@example.com" }, as: :json
        assert_response :success
        body = JSON.parse(response.body)
        assert_equal 1, body["employees"].size
        assert_equal "Alice", body["employees"].first["first_name"]
        assert_equal 1, body["meta"]["total_count"]
      end

      test "GET index search matches job title" do
        get api_v1_employees_path, params: { q: "Product Manager" }, as: :json
        assert_response :success
        body = JSON.parse(response.body)
        assert_equal 1, body["employees"].size
        assert_equal "Bob", body["employees"].first["first_name"]
      end

      test "GET show returns one employee" do
        get api_v1_employee_path(@employee), as: :json
        assert_response :success
        body = JSON.parse(response.body)
        assert_equal @employee.id, body["id"]
        assert_equal "alice@example.com", body["email"]
      end

      test "GET show returns 404 for unknown id" do
        get api_v1_employee_path(id: 0), as: :json
        assert_response :not_found
      end

      test "POST create creates an employee" do
        assert_difference -> { Employee.count }, 1 do
          post api_v1_employees_path,
               params: {
                 employee: {
                   first_name: "Carol",
                   last_name: "Chen",
                   job_title: "Designer",
                   country: "CA",
                   salary: "78000.50",
                   currency: "CAD",
                   department: "Design",
                   hired_on: "2024-03-01",
                   employment_status: "active"
                 }
               },
               as: :json
        end
        assert_response :created
        body = JSON.parse(response.body)
        assert_equal "Carol Chen", body["full_name"]
        assert_equal "CAD", body["currency"]
      end

      test "POST create returns errors when invalid" do
        assert_no_difference -> { Employee.count } do
          post api_v1_employees_path,
               params: { employee: { first_name: "", last_name: "", job_title: "", country: "", salary: "" } },
               as: :json
        end
        assert_response :unprocessable_entity
        body = JSON.parse(response.body)
        assert_kind_of Array, body["errors"]
        assert body["errors"].any?
      end

      test "PATCH update updates an employee" do
        patch api_v1_employee_path(@employee),
              params: { employee: { job_title: "Lead Engineer", salary: "125000" } },
              as: :json
        assert_response :success
        assert_equal "Lead Engineer", @employee.reload.job_title
      end

      test "DELETE destroy removes an employee" do
        assert_difference -> { Employee.count }, -1 do
          delete api_v1_employee_path(@employee), as: :json
        end
        assert_response :no_content
      end
    end
  end
end
