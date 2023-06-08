class ChangePincodeDataTypeInMastersInterns < ActiveRecord::Migration[5.2]
  def change
    change_column :masters_interns, :pincode, :string
  end
end
