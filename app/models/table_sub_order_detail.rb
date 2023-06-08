class TableSubOrderDetail < ApplicationRecord

    belongs_to :table_sub_order, :class_name => 'TableSubOrder', foreign_key: :sub_order_id
    belongs_to :food_item, :class_name => 'MastersFoodItem', foreign_key: :recipe_id

end
