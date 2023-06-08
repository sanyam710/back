class RestaurantCategory < ApplicationRecord
    has_many :food_items, -> { order(:sort_by) }, :class_name => 'MastersFoodItem', foreign_key: :category_id
    has_many :published_food_items, -> { where(status_id: CONTENT_STATUS_PUBLISHED).order(:sort_by)}, :class_name => 'MastersFoodItem', foreign_key: :category_id
end
