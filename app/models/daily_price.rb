class DailyPrice < ApplicationRecord
  validates :ticker, presence: true
  validates :date, presence: true
  validates :close_price, presence: true, numericality: { greater_than: 0 }
  validates :ticker, uniqueness: { scope: :date, message: "이미 해당 날짜의 데이터가 존재합니다." }
end
