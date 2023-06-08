class CreateTableSubOrderDetails < ActiveRecord::Migration[5.2]
  def change
    create_table :table_sub_order_details do |t|
      t.integer :sub_order_id
      t.integer :recipe_id
      t.integer :quantity
      t.integer :current_price
      t.integer :current_total_price
      t.string :instruction

      t.timestamps
    end
  end
end
