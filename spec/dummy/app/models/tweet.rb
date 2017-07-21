class Tweet < ApplicationRecord
  belongs_to :parent, optional: true
  belongs_to :author, class_name: 'User'

  validates :content, presence: true
end
