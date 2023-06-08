class AddNutritionInfoToMastersFoodItems < ActiveRecord::Migration[5.2]
  def change
    add_column :masters_food_items, :nutrition_info, :json
  end
end
