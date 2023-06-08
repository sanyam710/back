class CreateRestaurantChildren < ActiveRecord::Migration[5.2]
  def change
    create_table :restaurant_children do |t|
      t.integer :restaurant_id
      t.string :name
      t.integer :status_id

      t.timestamps
    end
  end
end
