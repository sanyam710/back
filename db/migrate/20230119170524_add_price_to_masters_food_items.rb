class AddPriceToMastersFoodItems < ActiveRecord::Migration[5.2]
  def change
    add_column :masters_food_items, :price, :integer
  end
end
