class RemoveIngredientsInfoFromMastersFoodItems < ActiveRecord::Migration[5.2]
  def change
    remove_column :masters_food_items, :ingredients_info, :string
  end
end
