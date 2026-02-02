class Visit < ApplicationRecord
  validates :ip_address, presence: true
  validates :visited_date, presence: true
  
  # 고유 방문자 식별을 위한 스코프
  scope :today, -> { where(visited_date: Date.today) }
  scope :on_date, ->(date) { where(visited_date: date) }
  
  # 통계 메서드
  def self.total_visits
    Rails.cache.fetch('visits_total_count', expires_in: 1.hour) do
      count
    end
  end
  
  # 고유 방문자 수 계산 (IP+User-Agent 조합으로 중복 제거)
  def self.total_unique_visitors
    Rails.cache.fetch('visits_unique_visitors_count', expires_in: 1.hour) do
      # IP 주소와 User-Agent 조합으로 고유 방문자 수 계산
      # group을 사용하여 고유 조합의 개수를 계산
      group(:ip_address, :user_agent).count.size
    end
  end
  
  def self.daily_visits(date = Date.today)
    Rails.cache.fetch("visits_daily_#{date}", expires_in: 1.hour) do
      on_date(date).count
    end
  end
  
  # 일일 고유 방문자 수 계산
  def self.daily_unique_visitors(date = Date.today)
    Rails.cache.fetch("visits_daily_unique_#{date}", expires_in: 1.hour) do
      on_date(date).group(:ip_address, :user_agent).count.size
    end
  end
  
  def self.record_visit(ip_address, user_agent)
    visited_date = Date.today
    
    # 중복 방문 체크 (같은 IP+User-Agent+날짜 조합은 한 번만 기록)
    visit = find_or_create_by(
      ip_address: ip_address,
      user_agent: user_agent&.truncate(255),
      visited_date: visited_date
    )
    
    # 캐시 무효화
    Rails.cache.delete('visits_total_count')
    Rails.cache.delete('visits_unique_visitors_count')
    Rails.cache.delete("visits_daily_#{visited_date}")
    Rails.cache.delete("visits_daily_unique_#{visited_date}")
    
    visit
  end
end
