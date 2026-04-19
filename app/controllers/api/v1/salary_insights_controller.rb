# frozen_string_literal: true

module Api
  module V1
    class SalaryInsightsController < Api::ApplicationController
      def index
        if params[:country].present? && params.key?(:job_title)
          payload, status = job_title_in_country_payload
        elsif params[:country].present?
          payload, status = country_payload
        else
          payload = global_payload
          status = :ok
        end
        render json: payload, status: status
      end

      private

      def global_payload
        rows = aggregate_by_country_currency.to_a
        {
          by_country: rows.map { |row| serialize_aggregate_row(row) },
          summary: {
            total_employees: Employee.count,
            countries_represented: rows.map(&:country).uniq.size
          },
          extras: {
            total_payroll_by_currency: total_payroll_by_currency
          }
        }
      end

      def country_payload
        country = normalize_country_param(params[:country])
        return [ { error: "Invalid country code" }, :bad_request ] unless country

        scope = Employee.where(country: country)
        return [ empty_country(country), :not_found ] if scope.none?

        segments = scope.group(:currency).select(
          :currency,
          Arel.sql("COUNT(*)::bigint AS employee_count"),
          Arel.sql("MIN(salary) AS salary_min"),
          Arel.sql("MAX(salary) AS salary_max"),
          Arel.sql("AVG(salary) AS salary_avg"),
          median_sql("salary", as: "salary_median")
        ).map do |row|
          currency = row.currency
          seg_scope = scope.where(currency: currency)
          {
            currency: currency,
            employee_count: row.employee_count.to_i,
            salary_min: decimal_to_f(row.salary_min),
            salary_max: decimal_to_f(row.salary_max),
            salary_avg: decimal_to_f(row.salary_avg),
            salary_median: decimal_to_f(row.salary_median),
            by_job_title: job_title_breakdown(seg_scope),
            by_employment_status: employment_status_breakdown(seg_scope)
          }
        end

        [
          {
            country: country,
            segments: segments,
            total_employees: scope.count,
            extras: {
              distinct_job_titles: scope.distinct.count(:job_title)
            }
          },
          :ok
        ]
      end

      def job_title_in_country_payload
        country = normalize_country_param(params[:country])
        return [ { error: "Invalid country code" }, :bad_request ] unless country

        title = params[:job_title].to_s.strip
        return [ { error: "job_title is required" }, :bad_request ] if title.blank?

        pattern = "%#{ActiveRecord::Base.sanitize_sql_like(title)}%"
        scope = Employee.where(country: country).where("TRIM(job_title) ILIKE ?", pattern)

        return [ empty_job_title_country(country, title), :not_found ] if scope.none?

        segments = scope.group(:currency).select(
          :currency,
          Arel.sql("COUNT(*)::bigint AS employee_count"),
          Arel.sql("MIN(salary) AS salary_min"),
          Arel.sql("MAX(salary) AS salary_max"),
          Arel.sql("AVG(salary) AS salary_avg"),
          median_sql("salary", as: "salary_median")
        ).map do |row|
          {
            currency: row.currency,
            employee_count: row.employee_count.to_i,
            salary_min: decimal_to_f(row.salary_min),
            salary_max: decimal_to_f(row.salary_max),
            salary_avg: decimal_to_f(row.salary_avg),
            salary_median: decimal_to_f(row.salary_median)
          }
        end

        [
          {
            country: country,
            job_title: title,
            segments: segments,
            total_employees: scope.count
          },
          :ok
        ]
      end

      def aggregate_by_country_currency
        Employee.group(:country, :currency).select(
          :country, :currency,
          Arel.sql("COUNT(*)::bigint AS employee_count"),
          Arel.sql("MIN(salary) AS salary_min"),
          Arel.sql("MAX(salary) AS salary_max"),
          Arel.sql("AVG(salary) AS salary_avg"),
          median_sql("salary", as: "salary_median")
        ).order(:country, :currency)
      end

      def total_payroll_by_currency
        Employee.group(:currency).select(
          :currency,
          Arel.sql("SUM(salary) AS payroll_total"),
          Arel.sql("COUNT(*)::bigint AS employee_count")
        ).map do |row|
          {
            currency: row.currency,
            payroll_total: decimal_to_f(row.read_attribute("payroll_total")),
            employee_count: row.read_attribute("employee_count").to_i
          }
        end
      end

      def job_title_breakdown(scope)
        scope.group(:job_title).select(
          :job_title,
          Arel.sql("COUNT(*)::bigint AS employee_count"),
          Arel.sql("MIN(salary) AS salary_min"),
          Arel.sql("MAX(salary) AS salary_max"),
          Arel.sql("AVG(salary) AS salary_avg"),
          median_sql("salary", as: "salary_median")
        ).order(Arel.sql("AVG(salary) DESC")).map do |row|
          {
            job_title: row.job_title,
            employee_count: row.employee_count.to_i,
            salary_min: decimal_to_f(row.salary_min),
            salary_max: decimal_to_f(row.salary_max),
            salary_avg: decimal_to_f(row.salary_avg),
            salary_median: decimal_to_f(row.salary_median)
          }
        end
      end

      def employment_status_breakdown(scope)
        scope.group(:employment_status).select(
          :employment_status,
          Arel.sql("COUNT(*)::bigint AS employee_count"),
          Arel.sql("AVG(salary) AS salary_avg")
        ).map do |row|
          raw = row.read_attribute_before_type_cast(:employment_status)
          {
            employment_status: Employee.employment_statuses.key(raw),
            employee_count: row.employee_count.to_i,
            salary_avg: decimal_to_f(row.salary_avg)
          }
        end
      end

      def median_sql(column, as:)
        col = Employee.connection.quote_column_name(column)
        Arel.sql("PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY #{col}) AS #{as}")
      end

      def serialize_aggregate_row(row)
        {
          country: row.country,
          currency: row.currency,
          employee_count: row.employee_count.to_i,
          salary_min: decimal_to_f(row.salary_min),
          salary_max: decimal_to_f(row.salary_max),
          salary_avg: decimal_to_f(row.salary_avg),
          salary_median: decimal_to_f(row.salary_median)
        }
      end

      def decimal_to_f(value)
        return if value.nil?

        value.is_a?(BigDecimal) ? value.to_f : value.to_f
      end

      def normalize_country_param(raw)
        c = raw.to_s.strip.upcase
        c if c.match?(/\A[A-Z]{2}\z/)
      end

      def empty_country(country)
        {
          error: "No employees found for this country",
          country: country,
          segments: [],
          total_employees: 0
        }
      end

      def empty_job_title_country(country, title)
        {
          error: "No employees match this job title in the selected country",
          country: country,
          job_title: title,
          segments: [],
          total_employees: 0
        }
      end
    end
  end
end
