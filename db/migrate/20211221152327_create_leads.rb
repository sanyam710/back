class CreateLeads < ActiveRecord::Migration[5.2]
  def change
    create_table :leads do |t|
      t.integer :intern_id
      t.string :restaurant_name
      t.string :address
      t.string :manager_name
      t.bigint :mobile_no
      t.string :email

      t.timestamps
    end
  end
end
