class AddNewColumnInUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users , :google_reviews, :string
  end
end
