class Lead < ApplicationRecord
    validates :email, uniqueness: true
    validates :mobile_no, uniqueness: true

    # belongs_to :intern, class_name: "Masters::Intern", foreign_key: "inter_id"
    belongs_to :intern, :class_name => "Masters::Intern", foreign_key: :intern_id

end
