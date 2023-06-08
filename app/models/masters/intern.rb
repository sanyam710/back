class Masters::Intern < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  before_create :update_api_key
  validates :email, uniqueness: true
  validates :mobile_no, uniqueness: true
  has_many :leads, :class_name => 'Lead', foreign_key: :intern_id



  def update_api_key
    self.api_key = 32.times.map { [*'A'..'Z', *'a'..'z', *'0'..'9'].sample }.join
  end

end
