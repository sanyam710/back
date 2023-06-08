class InternController < ApplicationController
    before_action :authenticate_admin, only: [:create_intern,:update_intern,:get_all_interns,:get_intern_profile]
    before_action :authenticate_intern, only: [:update_password]

    def create_intern
        unless has_sufficient_params(['email'])
            return
        end

        intern = Masters::Intern.where(email: params[:email]).first
        if intern
            render_error_json "This email is already registered with us."
            return
        end

        intern = Masters::Intern.new
        intern.email = params[:email]
        intern.name = params[:name]
        intern.status_id = params[:status_id]
        intern.mobile_no = params[:mobile_no]
        intern.city = params[:city]
        intern.state = params[:state]
        intern.pincode = params[:pincode]
        intern.gender = params[:gender]
        intern.password = params[:password]

        if intern.save
            render_result_json intern
        else
            render_500_json intern.errors.full_messages.first
        end
    end

    def update_intern
        unless has_sufficient_params(['id'])
            return
        end

        intern = Masters::Intern.where(id: params[:id]).first
        unless intern
            render_error_json "Intern not found!"
            return
        end

        intern.email = params[:email] if params[:email].present?
        intern.name = params[:name] if params[:name].present?
        intern.status_id = params[:status_id] if params[:status_id].present?
        intern.mobile_no = params[:mobile_no] if params[:mobile_no].present?
        intern.city = params[:city] if params[:city].present?
        intern.state = params[:state] if params[:state].present?
        intern.pincode = params[:pincode] if params[:pincode].present?
        intern.gender = params[:gender] if params[:gender].present?
        intern.password = params[:password] if params[:password].present?


        if intern.save
            render_result_json intern
        else
            render_500_json intern.errors.full_messages.first
        end
    end

    def get_all_interns
        interns = Masters::Intern.all
        render_result_json interns
    end

    def get_intern_profile
        unless has_sufficient_params(['id'])
            return
        end

        intern = Masters::Intern.where(id: params[:id]).first
        if intern.present?
            render_result_json intern
        else
            render_error_json 'Intern not present.'
        end
    end

    def request_account_access
        unless has_sufficient_params(['email','password'])
            return
        end

        intern = Masters::Intern.where('email ilike ?', params[:email]).first
        
        unless intern
            render_error_json 'Invalid Access. Please check your Email and Password.'
            return
        end

        unless intern.valid_password?(params[:password])
            render_error_json 'Invalid Access. Please check your Email and Password.'
            return
        end

        unless intern.status_id == CONTENT_STATUS_PUBLISHED
            render_error_json 'Your Account is not Active yet.'
            return
        end

        render_result_json intern
    end

    def update_password
        unless has_sufficient_params(['old_password', 'new_password','retype_new_password'])
            return
        end

        if params[:new_password] != params[:retype_new_password]
            render_error_json 'Password dose not match'
            return
        end

        unless @intern.valid_password?(params[:old_password])
            render_error_json "Old password dosen't match"
            return
        end

        @intern.password = params[:new_password]
        @intern.save(validate: false)

        render_success_json "New password updated successfully"
    end

end
