class AddTaxToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :tax, :integer
  end
end
