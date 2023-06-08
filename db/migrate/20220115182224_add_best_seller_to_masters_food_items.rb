class AddBestSellerToMastersFoodItems < ActiveRecord::Migration[5.2]
  def change
    add_column :masters_food_items, :best_seller, :boolean
  end
end
