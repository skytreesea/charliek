# 기사생성기 Article 모델 (development 전용)
class Article < ApplicationRecord
  belongs_to :user, optional: true

  validates :title, presence: true

  scope :recent, -> { order(created_at: :desc) }

  def owned_by?(user)
    user.present? && user_id.present? && user_id == user.id
  end

  # 수정/삭제 가능: 본인 글 또는 수퍼관리자
  def editable_by?(user)
    return false if user.blank?
    user.super_admin? || owned_by?(user)
  end

  # 최근 기간 내 저장된 기사의 키워드 빈도 기반 트렌딩 키워드 (상위 limit개)
  # 평범한 키워드(기업실적, 주식시장 등)는 필터링하여 시의성 있는 것만 반환
  def self.trending_keywords(since: 7.days.ago, limit: 30)
    return [] unless table_exists?

    rows = where("created_at >= ? AND keywords IS NOT NULL AND TRIM(keywords) != ''", since).pluck(:keywords)
    return [] if rows.blank?

    count = Hash.new(0)
    rows.each do |keywords_str|
      keywords_str.to_s.split(/,/).map(&:strip).reject(&:blank?).each do |kw|
        count[kw] += 1 unless generic_keyword?(kw)
      end
    end
    count.sort_by { |_, v| -v }.first(limit).map(&:first)
  end

  GENERIC_KEYWORDS = [
    "기업실적", "기업 실적", "주식시장", "주식 시장", "금리", "유가", "환율",
    "인플레이션", "글로벌경제", "글로벌 경제", "국제정세", "국제 정세",
    "핵심키워드", "핵심 키워드", "최신뉴스", "최신 뉴스", "사회이슈", "사회 이슈", "정책"
  ].freeze

  def self.generic_keyword?(kw)
    return true if kw.blank? || kw.length < 2
    kw_normalized = kw.to_s.strip
    GENERIC_KEYWORDS.any? { |g| kw_normalized.include?(g) || g.include?(kw_normalized) }
  end
end
