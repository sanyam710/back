class RenameStatusColumns < ActiveRecord::Migration[5.2]
  def change
    rename_column :table_sub_orders, :status, :status_id
    rename_column :table_orders, :status, :status_id
    rename_column :restaurant_tables, :status, :status_id
  end
end
