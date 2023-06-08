class CreateTableSubOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :table_sub_orders do |t|
      t.integer :table_order_id
      t.integer :status
      t.integer :total_price
      t.string :instruction

      t.timestamps
    end
  end
end
