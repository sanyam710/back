class User < ApplicationRecord
    # Include default devise modules. Others available are:
    # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
    devise :database_authenticatable, :registerable,
           :recoverable, :rememberable, :validatable

    validates :email, uniqueness: true
    validates :mobile_no, uniqueness: true
    before_create :update_api_key,:update_menu_key,:update_default_language
    after_commit :update_restaurant_tables
    has_many :categories, :class_name => 'RestaurantCategory', foreign_key: :restaurant_id
    has_many :languages, :class_name => 'UserLanguage', foreign_key: :user_id
    has_one :published_logo, -> { where(entity_type: ENTITY_TYPE_LOGO,status_id: CONTENT_STATUS_PUBLISHED) }, class_name: 'EntityImage', foreign_key: :entity_type_id
    has_one :published_hr_logo, -> { where(entity_type: ENTITY_TYPE_HORIZONTAL_LOGO,status_id: CONTENT_STATUS_PUBLISHED) }, class_name: 'EntityImage', foreign_key: :entity_type_id
    has_many :banner_images, -> { where(entity_type: ENTITY_TYPE_BANNER_IMAGE,status_id: CONTENT_STATUS_PUBLISHED) }, class_name: 'EntityImage', foreign_key: :entity_type_id
    has_many :gallery_images, -> { where(entity_type: ENTITY_TYPE_GALLERY_IMAGE,status_id: CONTENT_STATUS_PUBLISHED) }, class_name: 'EntityImage', foreign_key: :entity_type_id
    belongs_to :default_language, :class_name => "MastersLanguage", foreign_key: :default_language_id
    has_many :tables, -> { order('sort_by ASC') }, class_name: 'RestaurantTable', foreign_key: :restaurant_id
    has_many :children, class_name: 'RestaurantChild', foreign_key: :restaurant_id


    def update_api_key
        self.api_key = 32.times.map { [*'A'..'Z', *'a'..'z', *'0'..'9'].sample }.join
    end

    def update_menu_key
        self.menu_key = 32.times.map { [*'A'..'Z', *'a'..'z', *'0'..'9'].sample }.join
    end

    def update_default_language
        self.default_language_id = 1
    end

    def update_restaurant_tables
        limit = self.no_of_tables
        if (limit != nil && limit != 0)
            (limit + 1).times do |l|
                if l == 0
                    name = "Parcel/Take Away"
                else
                    name = "Table-" + (l.to_i).to_s
                end
                table = RestaurantTable.where(restaurant_id: self.id, name: name, sort_by: l).first_or_initialize
                table.save
            end
        end
    end

end
