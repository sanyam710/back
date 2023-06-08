class AddRestaurantChildIdToMastersFoodItemChild < ActiveRecord::Migration[5.2]
  def change
    add_column :masters_food_item_children, :restaurant_child_id, :integer
  end
end
