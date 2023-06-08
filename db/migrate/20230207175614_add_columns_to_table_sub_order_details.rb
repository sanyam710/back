class AddColumnsToTableSubOrderDetails < ActiveRecord::Migration[5.2]
  def change
    add_column :table_sub_order_details, :recipe_child_id, :integer
    add_column :table_sub_order_details, :child_current_price, :integer
    add_column :table_sub_order_details, :child_name, :string
  end
end
