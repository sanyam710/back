class RemoveColorFieldsFromUsers < ActiveRecord::Migration[5.2]
  def change
    remove_column :users, :color1, :string
    remove_column :users, :color2, :string
    remove_column :users, :color3, :string
  end
end
