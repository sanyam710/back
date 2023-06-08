class TableOrder < ApplicationRecord

    has_many :sub_orders, -> { order('created_at DESC') }, :class_name => 'TableSubOrder', foreign_key: :table_order_id
    belongs_to :table, :class_name => 'RestaurantTable', foreign_key: :table_id
    after_commit :update_restaurant_tables


    def update_restaurant_tables
        if self.status_id == ORDER_COMPLETED
            sub_orders = self.sub_orders
            if sub_orders.present?
                sub_orders.update_all(status_id: ORDER_COMPLETED)
            end
        end
    end

end
