class AddColumnInMastersFoodItems < ActiveRecord::Migration[5.2]
  def change
    add_column :masters_food_items ,:recipes_description , :string
  end
end
