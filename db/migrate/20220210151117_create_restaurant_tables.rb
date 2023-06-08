class CreateRestaurantTables < ActiveRecord::Migration[5.2]
  def change
    create_table :restaurant_tables do |t|
      t.integer :restaurant_id
      t.string :name
      t.integer :latest_order_id
      t.integer :status

      t.timestamps
    end
  end
end
