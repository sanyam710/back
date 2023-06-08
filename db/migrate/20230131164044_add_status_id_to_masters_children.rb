class AddStatusIdToMastersChildren < ActiveRecord::Migration[5.2]
  def change
    add_column :masters_children, :status_id, :integer
  end
end
