class RestaurantController < ApplicationController

    require 'csv'
    before_action :authenticate_user, except: [:generate_enquiry,:export_recipes,:get_all_enquiries,:update_enquiry,:remove_enquiry,:get_enquiry_by_id,:add_or_update_master_child,:get_all_masters_child,:remove_master_child]
    before_action :authenticate_admin, only: [:get_all_enquiries,:update_enquiry,:remove_enquiry,:get_enquiry_by_id,:add_or_update_master_child,:get_all_masters_child,:remove_master_child]


    def remove_category
        unless has_sufficient_params(['id'])
            return
        end

        category = RestaurantCategory.where(id: params[:id]).first

        if category.present?
            foods = category.food_items
            foods.update_all(status_id: CONTENT_STATUS_DISCARDED)
            category.status_id = CONTENT_STATUS_DISCARDED
            category.save
            render_success_json 'Category Removed !'
        else
            render_error_json 'Category not present.'
            return
        end
    end

    def add_or_update_category
        if params[:id].present?
            category = RestaurantCategory.where(id: params[:id]).first

            unless category
                render_error_json 'Category not present.'
                return
            end
            if category.present?
                category.name = params[:name].strip.titleize if params[:name].present?
                category.status_id = params[:status_id] if params[:status_id].present?
                category.save
                render_success_json 'Category Updated !'
            end
        else
            unless has_sufficient_params(['restaurant_id','name'])
                return
            end
            restaurant_category = RestaurantCategory.new
            restaurant_category.name = params[:name].strip.titleize
            restaurant_category.restaurant_id = params[:restaurant_id]
            restaurant_category.status_id = CONTENT_STATUS_PUBLISHED
    
            if restaurant_category.save
                render_result_json restaurant_category
            end
        end
    end

    def get_all_categories
        categories = @user.categories.includes(:published_food_items).where('restaurant_categories.status_id = ?',CONTENT_STATUS_PUBLISHED).order('created_at desc')
        map = []

        categories.each do |cat|
            recipes_count = cat.published_food_items.count rescue 0
            map << {id: cat.id, name: cat.name, cat_id: [cat.id.to_s], recipes_count: recipes_count, sort_by: cat.sort_by}
        end

        render_result_json map
    end

    def get_all_recipes
        recipes = MastersFoodItem.where(category_id: @user.categories.ids, status_id: CONTENT_STATUS_PUBLISHED)
        render_result_json recipes
    end

    def create_food_item
        unless has_sufficient_params(['restaurant_id','category_id','name'])
            return
        end
        masters_food_item = MastersFoodItem.new
        masters_food_item.name = params[:name].strip.titleize
        masters_food_item.category_id = params[:category_id]
        masters_food_item.restaurant_id = params[:restaurant_id]
        masters_food_item.status_id = CONTENT_STATUS_DRAFT
        if masters_food_item.save
            render_result_json masters_food_item
        end
    end

    def create_food_item_in_bulk
        unless has_sufficient_params(['restaurant_id','category_id','recipe_names'])
            return
        end
        recipe_names = params[:recipe_names]
        created_food_items = []
        recipe_names.each do |recipe_name|
            masters_food_item = MastersFoodItem.new
            masters_food_item.name = recipe_name.strip.titleize
            masters_food_item.category_id = params[:category_id]
            masters_food_item.restaurant_id = params[:restaurant_id]
            masters_food_item.status_id = CONTENT_STATUS_DRAFT
            if masters_food_item.save
                obj = {}
                obj['id'] = masters_food_item.id
                obj['name'] = masters_food_item.name
                obj['status_id'] = masters_food_item.status_id
                created_food_items << obj
            end
        end
        render_result_json created_food_items
    end

    def get_food_item_details_by_id
        unless has_sufficient_params(['id','restaurant_id'])
            return
        end
        masters_food_item = MastersFoodItem.includes(food_item_children: :master).where(id: params[:id]).first
        unless masters_food_item
            render_error_json 'Food Item Not Present.'
            return
        end
        user = User.includes([languages: :master]).where(id: params[:restaurant_id]).first
        food_items_alias_arr = []
        if user.languages.present?
            user_languages = user.languages
            user_languages.each do |language|
                food_item_alias = FoodItemAlias.where(food_item_id: masters_food_item.id,language_id: language.master.id).first
                obj = {}
                obj['id'] = nil
                obj['language_name'] = language.master.name rescue nil
                obj['language_id'] = language.master.id rescue nil
                obj['alias'] = nil
                if food_item_alias.present?
                    obj['id'] = food_item_alias.id
                    obj['alias'] = food_item_alias.alias
                end
                food_items_alias_arr << obj
            end
        end
        children = []
        if masters_food_item.food_item_children.present?
            masters_food_item.food_item_children.each do |child|
                obj = {}
                obj['id'] = child.id
                obj['child_name'] = child.master.name
                obj['child_price'] = child.price
                obj['child_id'] = child.id
                children << obj
            end
        end

        masters_food_item = masters_food_item.as_json
        recipe_ingredients = Recipe::Ingredient.where(recipe_id: params[:id])
        categories = User.where(id: params[:restaurant_id]).first.categories.where('restaurant_categories.status_id != ?',CONTENT_STATUS_DISCARDED).select(:id,:name)
        masters_food_item['categories'] = categories
        images = EntityImage.where(entity_type: ENTITY_TYPE_FOOD_ITEM,entity_type_id: params[:id],status_id: CONTENT_STATUS_PUBLISHED).select(:id,:url).as_json
        masters_food_item['recipe_images'] = images
        masters_food_item['food_item_aliases'] = food_items_alias_arr
        masters_food_item['ingredients'] = recipe_ingredients
        masters_food_item['children'] = children
        render_result_json masters_food_item
    end

    def update_food_item
        unless has_sufficient_params(['id'])
            return
        end
        masters_food_item = MastersFoodItem.find params[:id]
        unless masters_food_item
            render_error_json 'Food Item not present.'
        end

        masters_food_item.name = params[:name].strip.titleize if params[:name].present?
        masters_food_item.status_id = params[:status_id] if params[:status_id].present?
        masters_food_item.category_id = params[:category_id] if params[:category_id].present?
        masters_food_item.recipe_type = params[:recipe_type] if params[:recipe_type].present?
        masters_food_item.total_cooked_weight = params[:total_cooked_weight]
        masters_food_item.serving_description = params[:serving_description]
        masters_food_item.per_serving_weight = params[:per_serving_weight]
        masters_food_item.cooking_info = params[:cooking_info]
        masters_food_item.allergies_info = params[:allergies_info]
        masters_food_item.expiry_date = params[:expiry_date]
        masters_food_item.used_as_ingredient = params[:used_as_ingredient]
        masters_food_item.allergy_ids = params[:allergy_ids]
        masters_food_item.meal_type_ids = params[:meal_type_ids]
        masters_food_item.meal_types_info = params[:meal_types_info]
        masters_food_item.is_liquid = params[:is_liquid]
        masters_food_item.is_jain = params[:is_jain]
        masters_food_item.best_seller = params[:best_seller]
        masters_food_item.price = params[:price]
        masters_food_item.recipes_description = params[:recipes_description]
        if masters_food_item.save
            render_success_json "Details updated"
        end
    end

    def remove_food_item
        unless has_sufficient_params(['id'])
            return
        end
        masters_food_item = MastersFoodItem.find params[:id]
        unless masters_food_item
            render_error_json 'Food Item Not Present.'
            return
        end
        masters_food_item.status_id = CONTENT_STATUS_DISCARDED
        if masters_food_item.save
            render_success_json 'Food Item Removed !'
        end
    end

    def get_recipes_by_category
        unless has_sufficient_params(['id'])
            return
        end

        category = RestaurantCategory.find params[:id]
        unless category
            render_error_json 'Category not present.'
        end
        recipes = category.food_items.where('masters_food_items.status_id != ?',CONTENT_STATUS_DISCARDED).order(:sort_by)
        if recipes.present?
            map = []
            recipes.each do |recipe|
                map << {id: recipe.id, name: recipe.name, status_id: recipe.status_id, recipe_type: recipe.recipe_type, cat_id: recipe.category.id.to_s }
            end
            render_result_json map
        else
            render_success_json 'Recipes not available.'
        end

    end

    def search_recipe
        q = params[:name].downcase
        recipes = MastersFoodItem.joins(:category).where("masters_food_items.name ilike ? AND masters_food_items.status_id != ? AND masters_food_items.restaurant_id = ? AND restaurant_categories.status_id = ?","%#{q}%", CONTENT_STATUS_DISCARDED, params[:restaurant_id], CONTENT_STATUS_PUBLISHED)

        categories_arr = {}
        recipes_arr = {}
        recipes.each do |r|
            recipes_arr[r.category_id] = []
        end

        recipes.each do |r|
            cooked_weight = r.composition_quantity.to_f rescue 0
            serving_weight = r.restaurant_serving_weight.to_f rescue 0

            recipes_details = recipes.select(:id,:name,:status_id,:recipe_type)
            recipes_arr[r.category_id] << {id: r.id, name: r.name.titlecase, recipe_type: r.recipe_type, status_id: r.status_id}
            
            categories_arr[r.category_id] = {id: r.category_id, name: r.category.name, recipes: recipes_arr[r.category_id]}
        end
        
        render_result_json categories_arr
    end

    def get_qr_code_category
        unless has_sufficient_params(['restaurant_id'])
            return
        end
        user = User.where(id: params[:restaurant_id]).first
        if user.present?
            render_result_json user.qr_code_category
        else
            render_error_json 'User is not present.'
        end
    end

    def update_qr_code_category
        unless has_sufficient_params(['restaurant_id'])
            return
        end
        user = User.where(id: params[:restaurant_id]).first
        if user.present?
            user.qr_code_category = params[:qr_code_category]
            user.save
            render_success_json 'QR Code Category Updated.'
        else
            render_error_json 'User is not present.'
        end
    end

    def generate_enquiry
        unless has_sufficient_params(['name','email'])
            return
        end
        enquiry = Enquiry.new
        enquiry.name = params[:name]
        enquiry.email = params[:email]
        enquiry.mobile_no = params[:mobile_no] if params[:mobile_no].present?
        enquiry.city = params[:city]
        enquiry.message = params[:message]
        enquiry.status_id = CONTENT_STATUS_PUBLISHED
        enquiry.save

        render_success_json 'Enquiry generated.'
    end

    def get_all_enquiries
        enquiries = Enquiry.all
        render_result_json enquiries
    end

    def store_image
        unless has_sufficient_params(['entity_type','entity_type_id','url'])
            return
        end
        if params[:entity_type].to_i == ENTITY_TYPE_LOGO
            old_restaurant_logo = EntityImage.where(entity_type: ENTITY_TYPE_LOGO,entity_type_id: params[:entity_type_id],status_id: CONTENT_STATUS_PUBLISHED).first
            if old_restaurant_logo.present?
                old_restaurant_logo.update_attributes(status_id: CONTENT_STATUS_DRAFT)
            end
        end
        image = EntityImage.new
        image.entity_type = params[:entity_type]
        image.entity_type_id = params[:entity_type_id]
        image.url = params[:url]
        image.status_id = CONTENT_STATUS_PUBLISHED
        if image.save
            obj = {}
            obj['id'] = image.id
            obj['url'] = image.url
            render_result_json obj
        else
            render_error_json 'Something went wrong !'
        end
    end

    def remove_image
        unless has_sufficient_params(['id'])
            return
        end
        image = EntityImage.find params['id']
        unless image
            render_error_json 'Image not present.'
        end
        image.update_attributes(status_id: CONTENT_STATUS_DRAFT)
        render_success_json 'Image removed.'
    end

    def get_restaurant_logo
        unless has_sufficient_params(['restaurant_id'])
            return
        end
        map = {}
        user = User.includes(:published_logo,:published_hr_logo,:banner_images,:gallery_images).where(id: params[:restaurant_id]).first
        unless user
            render_error_json 'Restaurant not present.'
        end
        response_obj = {}

        response_obj['logo'] = {}
        if user.published_logo.present?
            obj = {}
            obj['id'] = user.published_logo.id
            obj['url'] = user.published_logo.url
            response_obj['logo'] = obj
        end

        response_obj['hr_logo'] = {}
        if user.published_hr_logo.present?
            obj = {}
            obj['id'] = user.published_hr_logo.id
            obj['url'] = user.published_hr_logo.url
            response_obj['hr_logo'] = obj
        end


        response_obj['banner_images'] = []
        if user.banner_images.present?
            banner_images = []
            user.banner_images.each do |banner_image|
                obj = {}
                obj['id'] = banner_image.id
                obj['url'] = banner_image.url
                banner_images << obj
            end
            response_obj['banner_images'] = banner_images
        end

        response_obj['gallery_images'] = []
        if user.gallery_images.present?
            gallery_images = []
            user.gallery_images.each do |gallery_image|
                obj = {}
                obj['id'] = gallery_image.id
                obj['url'] = gallery_image.url
                gallery_images << obj
            end
            response_obj['gallery_images'] = gallery_images
        end

        render_result_json response_obj
    end

    def copy_recipe
        unless has_sufficient_params(['id'])
            return
        end
        
        food_item = MastersFoodItem.where(id: params[:id]).first
        if food_item.present?
            recipe = food_item.dup
            recipe.status_id = CONTENT_STATUS_DRAFT

            if recipe.save
                map = {'id': recipe.id}
                render_result_json map
            end
        end
    end

    def set_recipe_category
        unless has_sufficient_params(['list'])
            return
        end

        params[:list].each_with_index do |item, index|
            MastersFoodItem.find(item[:id]).update_attributes(sort_by: index)
        end

        render_success_json 'Order updated'
    end

    def set_category_order
        unless has_sufficient_params(['list'])
            return
        end

        params[:list].each_with_index do |item, index|
            RestaurantCategory.find(item[:id]).update_attributes(sort_by: index)
        end

        render_success_json 'Order updated'
    end

    def export_recipes
        unless has_sufficient_params(['restaurant_id'])
            return
        end
        language_id = params[:language_id].to_i
        user = User.find params[:restaurant_id]
        food_items = MastersFoodItem.where(id: 2863).includes(:category,:ingredients,:aliases).where(restaurant_id: params[:restaurant_id]).all
        column_names = ['Name','Category','Status','Ingredients','Cooked Weight','Per Serving Cost Price']

        @csv = CSV.generate do |csv|
            csv << column_names
            food_items.each do |fi|
                arr = []
                name = fi.name
                if language_id.present? && (language_id != user.default_language_id)
                    aliases = fi.aliases
                    aliases.each do |ali|
                        if ali.language_id.to_i == language_id
                            name = ali.alias
                            break
                        end
                    end
                end
                arr[0] = name
                arr[1] = fi.category.name
                arr[2] = CONTENT_STATUS[fi.status_id]
                ingredients_name = []
                if fi.ingredients.present?
                    fi.ingredients.each do |ing|
                        ingredients_name << ing.ingredient_name
                    end
                end
                ingredients_name = ingredients_name.join(', ')
                arr[3] = ingredients_name
                arr[4] = fi.total_cooked_weight
                arr[5] = fi.price
                csv << arr
            end
        end

        respond_to do |format|
            format.html
            format.csv { send_data @csv, filename: "#{user.name.downcase}-recipes-#{Date.today}.csv" }
        end

    end

    def food_item_label
        unless has_sufficient_params(['id','restaurant_id'])
            return
        end
        # obj = {}
        food = MastersFoodItem.where(id: params[:id]).first.as_json
        recipe_image = EntityImage.where(entity_type: ENTITY_TYPE_FOOD_ITEM, entity_type_id: params[:id]).first
        if recipe_image.present?
            recipe_url = recipe_image.url
        end
        logo = EntityImage.where(entity_type: ENTITY_TYPE_LOGO, entity_type_id: params[:restaurant_id]).first
        if logo.present?
            logo_url = logo.url
        end
        food['recipe_url'] = recipe_url
        food['logo_url'] = logo_url

        render_result_json food
    end

    def update_enquiry
        unless has_sufficient_params(['id'])
            return
        end
        enquiry = Enquiry.where(id: params[:id]).first
        if enquiry.present?
            enquiry.update_attributes(status_id: params[:status_id])
        end
        render_success_json 'Enquiry Updated.'
    end

    def remove_enquiry
        unless has_sufficient_params(['id'])
            return
        end
        enquiry = Enquiry.where(id: params[:id]).first
        if enquiry.present?
            enquiry.delete
        end
        render_success_json 'Enquiry Removed.'
    end

    def get_enquiry_by_id
        unless has_sufficient_params(['id'])
            return
        end
        enquiry = Enquiry.where(id: params[:id]).first
        unless enquiry
            render_error_json 'Enquiry not present.'
            return
        end
        render_result_json enquiry
    end

    def update_food_item_aliases
        unless has_sufficient_params(['food_item_aliases','food_item_id'])
            return
        end
        food_item_id = params[:food_item_id]
        food_item_aliases = params[:food_item_aliases]
        food_item_aliases.each do |ali|
            id = ali['id']
            language_id = ali['language_id']
            food_alias = ali['alias']
            if id.present?
                food_item_alias = FoodItemAlias.where(id: id).first
                food_item_alias.alias = food_alias
                food_item_alias.save
            else
                food_item_alias = FoodItemAlias.where(food_item_id: food_item_id,language_id: language_id).first
                if !food_item_alias.present?
                    food_item_alias = FoodItemAlias.new
                end
                food_item_alias.food_item_id = food_item_id
                food_item_alias.language_id = language_id
                food_item_alias.alias = food_alias
                food_item_alias.save
            end
        end
        render_success_json 'Food Item Aliases updated.'
    end

    def search_ingredient
        unless has_sufficient_params(['query'])
            return
        end
        api_endpoint = 'https://api.spoonacular.com/food/ingredients/autocomplete?apiKey=6b5fbdf65dbf4428b80eb0e0aee219cf&query=' + params[:query] + '&metaInformation=true'
        response = HTTParty.get(api_endpoint)
        if response.present?
            map = response.map(&:clone)
            render_result_json map
        else
            render_error_json 'No ingredient found with the given keyword!'
        end
    end

    def get_ingredient_meta_information
        unless has_sufficient_params(['ingredient_id','serving_unit','quantity'])
            return
        end
        api_endpoint = 'https://api.spoonacular.com/food/ingredients/' + params[:ingredient_id].to_s + '/information?apiKey=6b5fbdf65dbf4428b80eb0e0aee219cf&amount=' + params[:quantity].to_s + '&unit=' + params[:serving_unit]
        response = HTTParty.get(api_endpoint)
        if response.present?
            render_result_json response
        else
            render_error_json 'Something went wrong!'
        end
    end

    def add_ingredient_to_recipe
        unless has_sufficient_params(['recipe_id','ingredient_id','ingredient_name','serving_unit','quantity'])
            return
        end
        recipe_ingredient = Recipe::Ingredient.new
        recipe_ingredient.recipe_id = params[:recipe_id]
        recipe_ingredient.ingredient_id = params[:ingredient_id]
        recipe_ingredient.ingredient_name = params[:ingredient_name]
        recipe_ingredient.serving_unit = params[:serving_unit]
        recipe_ingredient.quantity = params[:quantity]

        if params[:serving_unit].downcase != 'g'
            unit_conversion_api = 'https://api.spoonacular.com/recipes/convert/?apiKey=' + SPOONACULAR_API_KEY + '&ingredientName=' + params[:ingredient_name] + '&sourceAmount=' + params[:quantity].to_s + '&sourceUnit=' + params[:serving_unit] + '&targetUnit=g'
            response = HTTParty.get(unit_conversion_api)
            if response.present?
                total_gm_quantity = response['targetAmount']
            else
                nutrition_info = {}
            end
        else
            total_gm_quantity = params[:quantity].to_f
        end

        recipe_ingredient.total_gm_quantity = total_gm_quantity

        nutrition_info_api = 'https://api.spoonacular.com/food/ingredients/' + params[:ingredient_id].to_s + '/information?apiKey=' + SPOONACULAR_API_KEY + '&amount=' + params[:quantity].to_s + '&unit=' + params[:serving_unit]
        response = HTTParty.get(nutrition_info_api)
        if response.present?
            nutrition_info = response['nutrition']
        else
            nutrition_info = {}
        end

        recipe_ingredient.nutrition_info = nutrition_info
        if recipe_ingredient.save
            render_result_json recipe_ingredient
        else
            render_error_json 'Something went wrong!'
        end
    end

    def remove_ingredient_from_recipe
        unless has_sufficient_params(['id'])
            return
        end
        recipe_ingredient = Recipe::Ingredient.where(id: params[:id]).first
        unless recipe_ingredient
            render_error_json 'Ingredient not found.'
            return
        end
        recipe_ingredient.destroy
        render_success_json 'Ingredient removed!'
    end

    def edit_ingredient_in_recipe
        unless has_sufficient_params(['id'])
            return
        end
        recipe_ingredient = Recipe::Ingredient.where(id: params[:id]).first
        unless recipe_ingredient
            render_error_json 'Ingredient not found.'
            return
        end

        if params[:serving_unit].downcase != 'g'
            unit_conversion_api = 'https://api.spoonacular.com/recipes/convert/?apiKey=' + SPOONACULAR_API_KEY + '&ingredientName=' + params[:ingredient_name] + '&sourceAmount=' + params[:quantity].to_s + '&sourceUnit=' + params[:serving_unit] + '&targetUnit=g'
            response = HTTParty.get(unit_conversion_api)
            if response.present?
                total_gm_quantity = response['targetAmount']
            else
                nutrition_info = {}
            end
        else
            total_gm_quantity = params[:quantity].to_f
        end

        nutrition_info_api = 'https://api.spoonacular.com/food/ingredients/' + params[:ingredient_id].to_s + '/information?apiKey=' + SPOONACULAR_API_KEY + '&amount=' + params[:quantity].to_s + '&unit=' + params[:serving_unit]
        response = HTTParty.get(nutrition_info_api)
        if response.present?
            nutrition_info = response['nutrition']
        else
            nutrition_info = {}
        end

        recipe_ingredient.ingredient_name = params[:ingredient_name]
        recipe_ingredient.serving_unit = params[:serving_unit]
        recipe_ingredient.quantity = params[:quantity]
        recipe_ingredient.nutrition_info = nutrition_info
        recipe_ingredient.total_gm_quantity = total_gm_quantity
        if recipe_ingredient.save
            render_result_json recipe_ingredient
        else
            render_error_json 'Something went wrong!'
        end
    end

    def create_restaurant_tables
        unless has_sufficient_params(['restaurant_id','no_of_tables'])
            return
        end
        limit = params['no_of_tables'].to_i
        limit.times do |l|
            name = "Table-" + (l.to_i + 1).to_s
            table = RestaurantTable.where(restaurant_id: params[:restaurant_id],name: name).first_or_initialize
            table.save
        end
        render_result_json 'Tables created successfully.'
    end

    def update_browser_key
        unless has_sufficient_params(['restaurant_id','browser_key'])
            return
        end
        restaurant = User.find params[:restaurant_id]
        unless restaurant
            render_error_json 'Restaurant not found!'
            return
        end
        restaurant.browser_key = params[:browser_key]
        if restaurant.save
            render_success_json 'Browser key updated.'
        else
            render_error_json 'Something went wrong !'
        end
    end

    def get_tables_status
        tables = @user.tables
        map = []
        tables.each do |table|
            obj = {}
            obj['id'] = table.id
            obj['name'] = table.name
            ongoing_table_order = TableOrder.where(table_id: table.id, status_id: ORDER_ONGOING).first
            if ongoing_table_order.present?
                obj['any_ongoing_order'] = true
                ongoing_sub_order = ongoing_table_order.sub_orders.where(status_id: ORDER_ONGOING).first
                if ongoing_sub_order.present?
                    obj['ongoing_sub_order'] = true
                else
                    obj['ongoing_sub_order'] = false
                end
            else
                obj['any_ongoing_order'] = false
                obj['ongoing_sub_order'] = false
            end
            map << obj
        end
        render_result_json map
    end

    def add_or_update_master_child
        unless has_sufficient_params(['name'])
            return
        end
        if params[:id].present?
            master_child = Masters::Child.where(id: params[:id]).first
        else
            master_child = Masters::Child.new
        end
        master_child.name = params[:name]
        master_child.status_id = params[:status_id].present? ? params[:status_id] : CONTENT_STATUS_PUBLISHED
        master_child.save
        render_success_json master_child
    end

    def get_all_masters_child
        master_child = Masters::Child.all
        render_result_json master_child
    end

    def remove_master_child
        unless has_sufficient_params(['id'])
            return
        end
        master_child = Masters::Child.where(id: params[:id]).first
        unless master_child
            render_error_json 'Master Child not Found'
            return
        end
        if master_child.delete
            render_success_json 'Master child removed'
        end
    end

    def add_or_update_restaurant_child
        unless has_sufficient_params(['name', 'restaurant_id'])
            return
        end
        if params[:id].present?
            restaurant_child = RestaurantChild.where(id: params[:id]).first
        else
            restaurant_child = RestaurantChild.new
        end
        restaurant_child.name = params[:name]
        restaurant_child.status_id = params[:status_id].present? ? params[:status_id] : CONTENT_STATUS_PUBLISHED
        restaurant_child.restaurant_id = params[:restaurant_id]
        restaurant_child.save
        render_success_json restaurant_child
    end

    def get_all_restaurant_children
        restaurant_children = RestaurantChild.where(restaurant_id: params[:restaurant_id])
        render_result_json restaurant_children
    end

    def remove_restaurant_child
        unless has_sufficient_params(['id'])
            return
        end
        restaurant_child = RestaurantChild.where(id: params[:id]).first
        unless restaurant_child
            render_error_json 'Restaurant child not Found'
            return
        end
        if restaurant_child.delete
            render_success_json 'Restaurant child removed'
        end
    end

    def add_or_update_master_food_item_child
        unless has_sufficient_params(['food_item_id','child_id'])
            return
        end
        if params[:id].present?
            master_food_item_child = Masters::FoodItemChild.where(id: params[:id]).first
        else
            master_food_item_child = Masters::FoodItemChild.new
        end
        master_food_item_child.food_item_id = params[:food_item_id]
        master_food_item_child.child_id = params[:child_id]
        master_food_item_child.price = params[:price]
        if master_food_item_child.save
            obj = {}
            obj['id'] = master_food_item_child.id
            obj['child_id'] = master_food_item_child.master.id
            obj['child_name'] = master_food_item_child.master.name
            obj['child_price'] = master_food_item_child.price
            render_result_json obj
        end
    end

    def remove_master_food_item_child
        unless has_sufficient_params(['id'])
            return
        end
        master_food_item_child = Masters::FoodItemChild.where(id: params[:id]).first
        unless master_food_item_child
            render_error_json 'Master Food Item Child not Found'
            return
        end
        if master_food_item_child.delete
            render_success_json 'Master child removed'
        end
    end

    def add_or_update_master_food_item_child_v2
        unless has_sufficient_params(['food_item_id','restaurant_child_id'])
            return
        end
        if params[:id].present?
            master_food_item_child = Masters::FoodItemChild.where(id: params[:id]).first
        else
            master_food_item_child = Masters::FoodItemChild.new
        end
        master_food_item_child.food_item_id = params[:food_item_id]
        master_food_item_child.price = params[:price]
        master_food_item_child.restaurant_child_id = params[:restaurant_child_id]
        if master_food_item_child.save
            obj = {}
            obj['id'] = master_food_item_child.id
            obj['child_id'] = master_food_item_child.master.id
            obj['child_name'] = master_food_item_child.master.name
            obj['child_price'] = master_food_item_child.price
            render_result_json obj
        end
    end

end
