class AddDefaultLanguageIdToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :default_language_id, :integer
  end
end
