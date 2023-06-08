class Recipe::Ingredient < ApplicationRecord
    belongs_to :food_item, :class_name => "MastersFoodItem", foreign_key: :recipe_id
    after_commit :update_food_item_quantity, :update_food_item_nutrition_info

    def update_food_item_quantity
        food_item = self.food_item
        recipe_ingredients = food_item.ingredients
        total_food_cooked_weight = recipe_ingredients.sum(:total_gm_quantity)
        food_item.total_cooked_weight = total_food_cooked_weight
        food_item.save
    end

    def update_food_item_nutrition_info
        food_item = self.food_item
        recipe_ingredients = food_item.ingredients
        nutrition_info = []
        recipe_ingredients.each do |ing|
            ing_nutrition_info = ing.nutrition_info["nutrients"]
            ing_nutrition_info.each do |nutrient_info|
                nutrient_name = nutrient_info["name"]
                food_item_nutrient = nutrition_info.select { |f_nutrient| f_nutrient["name"] == nutrient_name }
                index = nutrition_info.index{ |item| item["name"] == nutrient_name }
                if food_item_nutrient[0].present?
                    food_item_nutrient[0]["amount"] = food_item_nutrient[0]["amount"] + nutrient_info["amount"]
                    food_item_nutrient[0]["amount"] = food_item_nutrient[0]["amount"].round(2)
                    food_item_nutrient[0]["name"] =  nutrient_name
                    food_item_nutrient[0]["title"] =  nutrient_info["title"]
                    food_item_nutrient[0]["unit"] =  nutrient_info["unit"]
                    nutrient_info[index] = food_item_nutrient
                else
                    obj = {}
                    obj["amount"] = nutrient_info["amount"].round(2)
                    obj["name"] =  nutrient_name
                    obj["title"] =  nutrient_info["title"]
                    obj["unit"] =  nutrient_info["unit"]
                    nutrition_info << obj
                end


            end
        end
        food_item.nutrition_info = nutrition_info
        food_item.save
    end

end
