class AddNoOfTablesToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :no_of_tables, :integer
  end
end
