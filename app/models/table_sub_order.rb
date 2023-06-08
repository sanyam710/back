class TableSubOrder < ApplicationRecord

    has_many :sub_order_details, :class_name => 'TableSubOrderDetail', foreign_key: :sub_order_id
    belongs_to :table_order, :class_name => 'TableOrder', foreign_key: :table_order_id
    after_save :update_total_price
    after_destroy :update_total_price_after_deleting_sub_order


    def update_total_price
        table_order = self.table_order
        total_price = table_order.total_price
        if !total_price.present?
            total_price = 0
        end
        if self.total_price.present?
            updated_total_price = total_price + self.total_price
        else
            updated_total_price = total_price
        end
        table_order.update_attributes(total_price: updated_total_price)
    end


    def update_total_price_after_deleting_sub_order
        table_order = self.table_order
        total_price = table_order.total_price
        if !total_price.present?
            total_price = 0
        end
        if self.total_price.present?
            updated_total_price = total_price - self.total_price
        else
            updated_total_price = total_price
        end
        table_order.update_attributes(total_price: updated_total_price)
    end


end
