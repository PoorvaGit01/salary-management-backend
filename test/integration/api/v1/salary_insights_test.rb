# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class SalaryInsightsTest < ActionDispatch::IntegrationTest
      test "GET salary_insights returns aggregates and summary" do
        get api_v1_salary_insights_path, as: :json
        assert_response :success
        body = JSON.parse(response.body)
        assert_kind_of Array, body["by_country"]
        assert body["by_country"].any? { |row| row["country"] == "US" }
        assert_equal "USD", body["by_country"].find { |r| r["country"] == "US" }["currency"]
        assert body["summary"]["total_employees"].positive?
        assert body["summary"]["countries_represented"].positive?
        assert_kind_of Array, body["extras"]["total_payroll_by_currency"]
      end

      test "GET salary_insights with country returns segments and job titles" do
        get api_v1_salary_insights_path, params: { country: "US" }, as: :json
        assert_response :success
        body = JSON.parse(response.body)
        assert_equal "US", body["country"]
        assert body["segments"].is_a?(Array)
        assert body["segments"].any?
        seg = body["segments"].first
        assert seg["salary_min"]
        assert seg["salary_max"]
        assert seg["salary_avg"]
        assert seg["salary_median"]
        assert seg["by_job_title"].is_a?(Array)
        assert seg["by_employment_status"].is_a?(Array)
      end

      test "GET salary_insights with country and job_title returns focused stats" do
        get api_v1_salary_insights_path,
            params: { country: "US", job_title: "Software Engineer" },
            as: :json
        assert_response :success
        body = JSON.parse(response.body)
        assert_equal "US", body["country"]
        assert_equal "Software Engineer", body["job_title"]
        assert body["segments"].any?
      end

      test "GET salary_insights unknown country returns 404" do
        get api_v1_salary_insights_path, params: { country: "ZZ" }, as: :json
        assert_response :not_found
      end

      test "GET salary_insights invalid country returns 400" do
        get api_v1_salary_insights_path, params: { country: "USA" }, as: :json
        assert_response :bad_request
      end

      test "GET salary_insights job_title without title returns 400" do
        get api_v1_salary_insights_path, params: { country: "US", job_title: "   " }, as: :json
        assert_response :bad_request
      end
    end
  end
end
