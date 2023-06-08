class RemovePerServingSellingPriceFromMastersFoodItems < ActiveRecord::Migration[5.2]
  def change
    remove_column :masters_food_items, :per_serving_selling_price, :number
  end
end
