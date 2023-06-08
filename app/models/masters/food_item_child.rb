class Masters::FoodItemChild < ApplicationRecord
    belongs_to :master, :class_name => "RestaurantChild", foreign_key: :restaurant_child_id
end
