class AddFssaiToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :fssai, :string
  end
end
