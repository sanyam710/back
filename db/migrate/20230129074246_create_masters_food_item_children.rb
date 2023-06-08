class CreateMastersFoodItemChildren < ActiveRecord::Migration[5.2]
  def change
    create_table :masters_food_item_children do |t|
      t.integer :child_id
      t.integer :food_item_id
      t.integer :price

      t.timestamps
    end
  end
end
