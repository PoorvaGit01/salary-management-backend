module Api
  module V1
    class EmployeesController < Api::ApplicationController
      MAX_PER_PAGE = 100
      DEFAULT_PER_PAGE = 25

      before_action :set_employee, only: %i[show update destroy]

      def index
        scope = Employee.order(:last_name, :first_name)
        scope = apply_search_filter(scope, params[:q])
        page, per_page = pagination_params
        total_count = scope.count
        records = scope.offset((page - 1) * per_page).limit(per_page)
        total_pages = total_count.zero? ? 0 : (total_count.to_f / per_page).ceil

        render json: {
          employees: records.map { |employee| employee_json(employee) },
          meta: {
            page: page,
            per_page: per_page,
            total_count: total_count,
            total_pages: total_pages
          }
        }
      end

      def show
        render json: employee_json(@employee)
      end

      def create
        employee = Employee.new(employee_params)
        if employee.save
          render json: employee_json(employee), status: :created, location: api_v1_employee_url(employee)
        else
          render json: { errors: employee.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @employee.update(employee_params)
          render json: employee_json(@employee)
        else
          render json: { errors: @employee.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @employee.destroy!
        head :no_content
      end

      private

      def pagination_params
        page = [ params[:page].to_i, 1 ].max
        requested = params[:per_page].to_i
        per_page = requested.positive? ? requested : DEFAULT_PER_PAGE
        per_page = [ per_page, MAX_PER_PAGE ].min
        [ page, per_page ]
      end

      def apply_search_filter(relation, q)
        q = q.to_s.strip
        return relation if q.blank?

        term = "%#{ActiveRecord::Base.sanitize_sql_like(q)}%"
        relation.where(
          <<~SQL.squish,
            employees.first_name ILIKE :term
            OR employees.last_name ILIKE :term
            OR employees.email ILIKE :term
            OR employees.job_title ILIKE :term
            OR COALESCE(employees.department, '') ILIKE :term
            OR COALESCE(employees.employee_number, '') ILIKE :term
          SQL
          term: term
        )
      end

      def set_employee
        @employee = Employee.find(params[:id])
      end

      def employee_params
        params.require(:employee).permit(
          :first_name,
          :last_name,
          :job_title,
          :country,
          :salary,
          :currency,
          :email,
          :department,
          :hired_on,
          :employment_status,
          :employee_number
        )
      end

      def employee_json(employee)
        employee.as_json(
          only: %i[
            id first_name last_name job_title country salary currency email department
            hired_on employment_status employee_number created_at updated_at
          ],
          methods: [ :full_name ]
        )
      end
    end
  end
end
