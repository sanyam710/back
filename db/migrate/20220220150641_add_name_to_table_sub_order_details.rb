class AddNameToTableSubOrderDetails < ActiveRecord::Migration[5.2]
  def change
    add_column :table_sub_order_details, :name, :string
  end
end
