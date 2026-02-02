# 매일 추천 키워드 (새 기사 작성기에서 하루 1회 갱신, 이후 shuffle하여 제시)
# 외부 뉴스 RSS(연합뉴스, 매일경제 등) 크롤링 → 시의성 키워드 우선
class DailyRecommendedKeyword < ApplicationRecord
  TARGET_COUNT = 40

  # 괄호가 붙어 있는 키워드 제외 (예: [속보], 【단독】 등)
  BRACKET_PATTERN = /[\[\]【】［］]/.freeze

  # 외부 뉴스에서 부족할 때만 보충 (구체적 주제 위주)
  FALLBACK_KEYWORDS = [
    "AI", "반도체", "스타트업", "M&A", "ESG", "IPO", "배당",
    "삼성전자", "SK하이닉스", "테슬라", "엔비디아", "애플", "마이크로소프트",
    "실적발표", "인수합병", "스핀오프", "테크기업", "바이오",
    "암호화폐", "메타버스", "전기차", "2차전지", "신재생에너지"
  ].freeze

  validates :date, presence: true, uniqueness: true
  validates :keywords, presence: true

  serialize :keywords, coder: JSON

  scope :for_date, ->(d) { where(date: d) }

  def self.for_today
    for_date(Time.current.to_date).first
  end

  def self.find_or_build_for_today
    record = for_today
    return record if record

    keywords = build_keywords_for_today
    create!(date: Time.current.to_date, keywords: keywords)
  end

  # 1순위: 외부 뉴스 RSS(NewsKeywordCrawlerService) → 2순위: Post → 3순위: Article → 4순위: FALLBACK
  def self.build_keywords_for_today
    # 1순위: 뉴스 키워드를 최우선으로 앞쪽에 전부 반영
    news_keywords = NewsKeywordCrawlerService.fetch_keywords(limit: 50) rescue []
    result = news_keywords.dup.reject { |k| keyword_has_bracket?(k) }

    # 2·3순위: 이미 포함된 키워드 제외하고 Post → Article 순으로 보충
    if defined?(Post)
      post_kw = Post.emerging_keywords(since: 14.days.ago, limit: 30)
        .reject { |k| result.include?(k) || keyword_has_bracket?(k) }
      result.concat(post_kw)
    end
    if defined?(Article)
      article_kw = Article.trending_keywords(since: 7.days.ago, limit: 20)
        .reject { |k| result.include?(k) || keyword_has_bracket?(k) }
      result.concat(article_kw)
    end

    result = result.first(TARGET_COUNT)

    return result if result.size >= TARGET_COUNT

    needed = TARGET_COUNT - result.size
    fallback = (FALLBACK_KEYWORDS - result).reject { |k| keyword_has_bracket?(k) }
    result + fallback.first(needed)
  end

  def self.keyword_has_bracket?(kw)
    kw.to_s.match?(BRACKET_PATTERN)
  end
  private_class_method :keyword_has_bracket?

  def shuffled_keywords
    (keywords || []).shuffle
  end
end
