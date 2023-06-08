class AddBrowserKeyToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :browser_key, :string
  end
end
