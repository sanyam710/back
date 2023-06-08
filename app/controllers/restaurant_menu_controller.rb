class RestaurantMenuController < ApplicationController

    def get_restaurant_details
        unless has_sufficient_params(['menu_key'])
            return
        end

        user = User.includes([languages: :master],:published_logo,:banner_images,:gallery_images,:tables).where(menu_key: params[:menu_key],status_id: CONTENT_STATUS_PUBLISHED).first

        unless user
            render_error_json 'User not present.'
            return
        end

        if user.start_date.present? && Date.parse(user.start_date.to_s) > Date.parse(Time.now.to_s)
            render_error_json 'Restaurant Account is not Active yet.'
            return
        end

        if user.end_date.present? && Date.parse(user.end_date.to_s) < Date.parse(Time.now.to_s)
            render_error_json 'Restaurant Account is Expired.'
            return
        end

        if user.visiting_count.present?
            visiting_count = user.visiting_count + 1
        else
            visiting_count = 1
        end
        user.update_columns(visiting_count: visiting_count)

        languages = []
        user.languages.each do |lang|
            languages << {id: lang.master.id,name: lang.master.name}
        end

        obj = {}
        obj['user'] = user.as_json(except: [:api_key,:created_at,:updated_at])
        obj['languages'] = languages
        obj['logo'] = user.published_logo.url rescue nil
        obj['slider_images'] = user.banner_images.pluck(:url) rescue nil
        obj['gallery_images'] = user.gallery_images.pluck(:url) rescue nil
        obj['tables'] = user.tables
        obj['server_key'] = SERVER_KEY
        obj['browser_key'] = user.browser_key

        render_result_json obj
    end


    def get_menu_details
        unless has_sufficient_params(['menu_key','language'])
            return
        end

        user = User.where(menu_key: params[:menu_key],status_id: CONTENT_STATUS_PUBLISHED).first

        if params[:language] == 'undefined' || !params[:language].present?
            language = user.default_language
        else
            language = MastersLanguage.where(id: params[:language]).first
            unless language
                render_error_json 'Something went wrong.'
                return
            end
        end

        meal_types = MEAL_TYPES
        allergies = ALLERGIES

        categories_id = user.present? && user.qr_code_category.present? ? user.qr_code_category.split("@") : []
        categories = RestaurantCategory.includes([published_food_items: [:aliases,:images,:ingredients,food_item_children: :master]]).where(id: categories_id).where(restaurant_id: user.id).where(status_id: CONTENT_STATUS_PUBLISHED).order('sort_by')

        all_categories = []

        categories.each do |cat|
            recipes = []
            cat.published_food_items.each do |fi|
                recipe_images = fi.images.pluck(:url) rescue nil

                recipe_allergies = []
                if fi.allergy_ids.present?
                    recipe_allergy_ids = fi.allergy_ids.split('@')
                    recipe_allergy_ids.each do |allergy_id|
                        ele = allergies.find{ |item| item['id'] == allergy_id.to_i }
                        if ele.present?
                            recipe_allergies << ele['name']
                        end
                    end
                end

                recipe_meal_types = []
                if fi.meal_type_ids.present?
                    recipe_meal_type_ids = fi.meal_type_ids.split('@')
                    recipe_meal_type_ids.each do |meal_type_id|
                        ele = meal_types.find{ |item| item['id'] == meal_type_id.to_i }
                        if ele.present?
                            recipe_meal_types << ele['name']
                        end
                    end
                end

                name = fi.name
                if language.present? && (language.id != user.default_language_id)
                    food_aliases = fi.aliases
                    if food_aliases.present?
                        food_aliases.each do |ali|
                            if ali.language_id == language.id.to_i
                                name = ali.alias
                                break
                            end
                        end
                    end
                end
                children = []
                if fi.food_item_children.present?
                    fi.food_item_children.each do |child|
                        obj = {}
                        obj['id'] = child.id
                        obj['child_name'] = child.master.name
                        obj['child_price'] = child.price
                        obj['child_id'] = child.id
                        children << obj
                    end
                end
                recipe = fi.as_json(except: [:name,:restaurant_id,:category_id,:api_key,:created_at,:updated_at,:allergy_ids,:meal_type_ids])
                recipe['name'] = name
                recipe['recipe_images'] = recipe_images
                recipe['allergies'] = recipe_allergies
                recipe['meal_types'] = recipe_meal_types
                recipe['ingredients'] = fi.ingredients
                recipe['children'] = children
                recipes << recipe
            end
            category = {id: cat.id, name: cat.name, recipes: recipes}
            all_categories << category
        end
        obj = {}
        obj['categories'] = all_categories
        render_result_json obj
    end



end
