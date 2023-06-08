class RestaurantTable < ApplicationRecord

    has_one :ongoing_order, -> { where(status_id: ORDER_ONGOING) }, class_name: 'TableOrder', foreign_key: :table_id
    has_many :orders, class_name: 'TableOrder', foreign_key: :table_id

end
