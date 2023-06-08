class MastersFoodItem < ApplicationRecord

    default_scope {order('sort_by asc')}

    belongs_to :category, :class_name => 'RestaurantCategory', foreign_key: :category_id
    has_many :aliases, :class_name => 'FoodItemAlias', foreign_key: :food_item_id
    has_many :ingredients, :class_name => 'Recipe::Ingredient', foreign_key: :recipe_id
    has_many :images, -> { where(entity_type: ENTITY_TYPE_FOOD_ITEM, status_id: CONTENT_STATUS_PUBLISHED) }, class_name: 'EntityImage', foreign_key: :entity_type_id
    has_many :food_item_children , :class_name => 'Masters::FoodItemChild', foreign_key: :food_item_id

end
