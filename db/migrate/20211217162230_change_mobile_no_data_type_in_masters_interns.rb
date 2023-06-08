class ChangeMobileNoDataTypeInMastersInterns < ActiveRecord::Migration[5.2]
  def change
    change_column :masters_interns, :mobile_no, :bigint
  end
end
