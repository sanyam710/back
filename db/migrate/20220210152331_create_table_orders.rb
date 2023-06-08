class CreateTableOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :table_orders do |t|
      t.integer :table_id
      t.integer :status
      t.integer :total_price
      t.string :instruction
      t.string :customer_name
      t.string :customer_email
      t.string :customer_mobile_no
      t.string :customer_address

      t.timestamps
    end
  end
end
