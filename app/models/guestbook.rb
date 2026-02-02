class Guestbook < ApplicationRecord
  validates :name, presence: true, length: { maximum: 50 }
  validates :content, presence: true, length: { maximum: 300 }
  
  scope :recent, -> { order(created_at: :desc) }
end
