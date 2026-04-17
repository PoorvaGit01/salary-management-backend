module Api
  module V1
    class EmployeesController < Api::ApplicationController
      before_action :set_employee, only: %i[show update destroy]

      def index
        employees = Employee.order(:last_name, :first_name)
        render json: employees.map { |employee| employee_json(employee) }
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
