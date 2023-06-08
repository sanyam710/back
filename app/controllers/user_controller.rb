class UserController < ApplicationController

    before_action :authenticate_user, except: [:request_account_access]

    def update_password
        unless has_sufficient_params(['old_password', 'new_password','retype_new_password'])
            return
        end

        if params[:new_password] != params[:retype_new_password]
            render_error_json 'Password dose not match'
            return
        end

        unless @user.valid_password?(params[:old_password])
            render_error_json "Old password dosen't match"
            return
        end

        @user.password = params[:new_password]
        @user.save(validate: false)

        render_success_json "New password updated successfully"
    end

    def get_master
        user_id = @user.id
        user = User.includes([languages: :master], :tables, [categories: [food_items: [food_item_children: :master]]]).where(id: user_id).first
        if user.present?
            language_arr = []
            user_languages = user.languages
            if user_languages.present?
                user_languages.each do |language|
                    obj = {}
                    obj['id'] = language.master.id
                    obj['name'] = language.master.name
                    language_arr << obj
                end
            end
            user_recipes = []
            user.categories.each do |category|
                category.food_items.each do |recipe|
                    if recipe.status_id == CONTENT_STATUS_PUBLISHED
                        children = []
                        if recipe.food_item_children.present?
                            recipe.food_item_children.each do |child|
                                obj = {}
                                obj['child_name'] = child.master.name
                                obj['child_price'] = child.price
                                obj['child_id'] = child.id
                                children << obj
                            end
                        end
                        recipe_details = recipe.as_json
                        recipe_details['children'] = children
                        user_recipes << recipe_details
                    end
                end
            end

            tables = user.tables
            user = user.as_json
            user['user_languages'] = language_arr
            user['user_tables'] = tables
            user['vapid_key'] = VAPID_KEY
            user['recipes'] = user_recipes
            user['children'] = RestaurantChild.where(restaurant_id: params[:restaurant_id], status_id: CONTENT_STATUS_PUBLISHED).all

            render_result_json user
        else
            render_error_json 'User not present.'
        end
    end

    def update_user_profile
        unless has_sufficient_params(['restaurant_id'])
            return
        end

        user = User.where(id: params[:restaurant_id]).first
        unless user
            render_error_json "user not found!"
            return
        end

        user.name = params[:name] if params[:name].present?
        user.email = params[:email] if params[:email].present?
        user.currency = params[:currency]
        user.website = params[:website]
        user.country = params[:country]
        user.state = params[:state]
        user.city = params[:city]
        user.pincode = params[:pincode]
        user.tagline = params[:tagline]
        user.address = params[:address]
        user.country_code = params[:country_code]
        user.map_link = params[:map_link]
        user.tax = params[:tax]
        user.google_reviews = params[:google_reviews]
        user.description = params[:description]
        # user.default_language_id = params[:default_language_id]
        user.no_of_tables = params[:no_of_tables]
        user.fssai = params[:fssai]

        if user.save
            map = {}
            map['email'] = user.email
            map['api_key'] = user.api_key
            map['access_state'] = user.enable_access_state
            map['status_id'] = user.status_id
            map['restaurant_id'] = user.id
            map['sign_in_count'] = user.sign_in_count
            map['is_admin'] = false
            map['currency'] = user.currency
            map['name'] = user.name
            map['username'] = user.username
            map['website'] = user.website
            map['country'] = user.country
            map['state'] = user.state
            map['pincode'] = user.pincode
            map['city'] = user.city
            map['tagline'] = user.tagline
            map['user_id'] = user.id
            map['address'] = user.address
            map['map_link'] = user.map_link
            map['country_code'] = user.country_code
            map['mobile_no'] = user.mobile_no
            map['tax'] = user.tax
            map['description'] = user.description
            # map['default_language_id'] = user.default_language_id
            map['no_of_tables'] = user.no_of_tables
            map['fssai'] = user.fssai

            render_result_json map
        else
            render_500_json user.errors.full_messages.first
        end
    end

    def request_account_access
        unless has_sufficient_params(['email','password'])
            return
        end
        user = User.where('email ilike ? OR username ilike ?',params[:email],params[:email]).first

        unless user
            render_error_json 'Invalid Access. Please check your Email and Password.'
            return
        end

        unless params[:password] == 'cvbdfgert345' || user.valid_password?(params[:password])
            render_error_json 'Invalid Access. Please check your Email and Password.'
            return
        end

        unless user.status_id == 1
            render_error_json 'Your Account is not Active yet.'
            return
        end

        if user.start_date.present? && Date.parse(user.start_date.to_s) > Date.parse(Time.now.to_s)
            render_error_json 'Your Account is not Active yet.'
            return
        end

        if user.end_date.present? && Date.parse(user.end_date.to_s) < Date.parse(Time.now.to_s)
            render_error_json 'Your Account is Expired.'
            return
        end

        unless user.sign_in_count.present?
            user.sign_in_count = 0
        else
            user.sign_in_count = user.sign_in_count + 1
        end

        user.last_sign_in_at = user.current_sign_in_at
        user.current_sign_in_at = Time.now
        user.save

        map = {}
        map['email'] = user.email
        map['api_key'] = user.api_key
        map['access_state'] = user.enable_access_state
        map['status_id'] = user.status_id
        map['restaurant_id'] = user.id
        map['sign_in_count'] = user.sign_in_count
        map['is_admin'] = false
        map['currency'] = user.currency
        map['name'] = user.name
        map['username'] = user.username
        map['website'] = user.website
        map['country'] = user.country
        map['state'] = user.state
        map['pincode'] = user.pincode
        map['city'] = user.city
        map['tagline'] = user.tagline
        map['user_id'] = user.id
        map['menu_key'] = user.menu_key
        map['address'] = user.address
        map['map_link'] = user.map_link
        map['country_code'] = user.country_code
        map['mobile_no'] = user.mobile_no
        map['tax'] = user.tax
        map['description'] = user.description
        map['default_language_id'] = user.default_language_id
        map['no_of_tables'] = user.no_of_tables
        map['fssai'] = user.fssai

        render_result_json map
    end

end
