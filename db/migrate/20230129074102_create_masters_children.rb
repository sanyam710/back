class CreateMastersChildren < ActiveRecord::Migration[5.2]
  def change
    create_table :masters_children do |t|
      t.string :name

      t.timestamps
    end
  end
end
