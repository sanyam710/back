class CreateRecipeIngredients < ActiveRecord::Migration[5.2]
  def change
    create_table :recipe_ingredients do |t|
      t.integer :recipe_id
      t.integer :ingredient_id
      t.string :ingredient_name
      t.string :serving_unit
      t.integer :quantity
      t.integer :total_gm_quantity
      t.json :nutrition_info

      t.timestamps
    end
  end
end
