class LeadsController < ApplicationController

    before_action :authenticate_intern, except: [:list_all_leads, :list_specific_intern_leads]
    before_action :authenticate_admin, only: [:list_all_leads]

    def generate_lead
        unless has_sufficient_params(['intern_id'])
            return
        end
        duplicate_lead = Lead.where('mobile_no = ? or email = ?',params[:mobile_no],params[:email])
        if duplicate_lead.present?
            render_error_json 'Lead with same email or mobile number is present.'
            return
        end
        lead = Lead.new
        lead.intern_id = params[:intern_id]
        lead.restaurant_name = params[:restaurant_name]
        lead.manager_name = params[:manager_name]
        lead.mobile_no = params[:mobile_no]
        lead.email = params[:email].downcase
        lead.address = params[:address]
        lead.comment = params[:comment]

        if lead.save
            render_result_json lead
        else
            render_error_json 'Something went wrong!'
        end

    end

    def update_lead
        unless has_sufficient_params(['id'])
            return
        end
        lead = Lead.where(id: params[:id]).first
        unless lead
            render_error_json "Lead not found!"
            return
        end

        duplicate_lead = Lead.where('mobile_no = ? or email = ?',params[:mobile_no],params[:email]).where.not(id: lead.id)
        if duplicate_lead.present?
            render_error_json 'Lead with same email or mobile number is present.'
            return
        end
        lead.restaurant_name = params[:restaurant_name] if params[:restaurant_name].present?
        lead.manager_name = params[:manager_name] if params[:manager_name].present?
        lead.mobile_no = params[:mobile_no] if params[:mobile_no].present?
        lead.email = params[:email].downcase if params[:email].present?
        lead.address = params[:address] if params[:address].present?
        lead.comment = params[:comment] if params[:comment].present?

        if lead.save
            render_result_json lead
        else
            render_error_json "Something went wrong!"
        end

    end

    def get_lead_by_id
        unless has_sufficient_params(['id'])
            return
        end
        lead = Lead.where(id: params[:id]).first
        if lead.present?
            render_result_json lead
        else
            render_error_json "Lead not found!"
        end
    end

    def list_specific_intern_leads
        unless has_sufficient_params(['intern_id'])
            return
        end
        is_valid_access = false

        admin = Admin.where(api_key: params[:api_key],status_id: CONTENT_STATUS_PUBLISHED).first
        if admin.present?
            is_valid_access = true
        else
            intern = Masters::Intern.where(api_key: params[:api_key],status_id: CONTENT_STATUS_PUBLISHED).first
            if intern.present?
                is_valid_access = true
            end
        end

        unless is_valid_access
            render_error_json 'Invalid access.'
        end
        leads = Lead.where(intern_id: params[:intern_id])
        render_result_json leads
    end

    def list_all_leads
        leads = Lead.includes(:intern).all
        render_result_json leads.as_json( :include => [:intern] )
    end

end
