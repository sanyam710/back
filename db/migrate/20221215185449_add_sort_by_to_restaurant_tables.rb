class AddSortByToRestaurantTables < ActiveRecord::Migration[5.2]
  def change
    add_column :restaurant_tables, :sort_by, :integer
  end
end
