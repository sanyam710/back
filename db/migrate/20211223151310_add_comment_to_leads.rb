class AddCommentToLeads < ActiveRecord::Migration[5.2]
  def change
    add_column :leads, :comment, :string
  end
end
