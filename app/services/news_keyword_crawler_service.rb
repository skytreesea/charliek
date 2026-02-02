# 외부 뉴스 사이트 RSS에서 최신 기사 제목을 크롤링해 시의성 있는 키워드 추출
# 내 데이터(Post, Article)가 아닌 연합뉴스, 매일경제, 서울경제 등에서 수집
class NewsKeywordCrawlerService
  # 한국 주요 뉴스 사이트 RSS (경제·증권·산업 위주)
  RSS_FEEDS = [
    "https://www.yna.co.kr/rss/economy.xml",           # 연합뉴스 경제
    "https://www.yna.co.kr/rss/market.xml",            # 연합뉴스 마켓+
    "https://www.yna.co.kr/rss/industry.xml",          # 연합뉴스 산업
    "https://www.yna.co.kr/rss/news.xml",              # 연합뉴스 최신기사
    "https://www.sedaily.com/rss",                     # 서울경제
    "https://www.mk.co.kr/rss/",                       # 매일경제
    "http://www.fnnews.com/rss/r20/fn_realnews_all.xml",  # 파이낸셜뉴스 전체
    "http://www.fnnews.com/rss/r20/fn_realnews_stock.xml", # 파이낸셜뉴스 증권
    "http://www.fnnews.com/rss/r20/fn_realnews_economy.xml", # 파이낸셜뉴스 경제
  ].freeze

  GENERIC_STOPWORDS = %w[
    뉴스 기사 분석 전망 관련 최신 시장 경제 투자 수익 실적 성과
    의 와 과 에 로 를 을 이 가 는 은 도 만 에서 대한 통해
    정리 요약 소개 소식 발표 공개 예정 가능 전략 포트폴리오
    주식 시장 유가 환율 금리 부동산
  ].freeze

  GENERIC_BLOCKLIST = [
    "기업실적", "기업 실적", "주식시장", "주식 시장", "금리", "유가", "환율",
    "인플레이션", "글로벌경제", "글로벌 경제", "국제정세", "국제 정세",
    "핵심키워드", "핵심 키워드", "최신뉴스", "최신 뉴스", "사회이슈", "사회 이슈", "정책"
  ].freeze

  class << self
    # RSS 피드들에서 제목 수집 → 키워드 추출 후 상위 limit개 반환
    def fetch_keywords(limit: 50)
      all_titles = []
      RSS_FEEDS.each do |url|
        titles = fetch_titles_from_rss(url)
        all_titles.concat(titles) if titles.present?
      rescue StandardError => e
        Rails.logger.warn "[NewsKeywordCrawler] Failed to fetch #{url}: #{e.message}"
      end

      return [] if all_titles.blank?

      extract_keywords_from_titles(all_titles, limit: limit)
    end

    private

    def fetch_titles_from_rss(url)
      response = Faraday.get(url, nil, { "User-Agent" => "CharlieK/1.0 (RSS Reader)" }) do |f|
        f.options.timeout = 10
        f.options.open_timeout = 6
      end

      return [] unless response.success?

      doc = Nokogiri::XML(response.body)
      # RSS 2.0: item/title, Atom: entry/title
      titles = doc.xpath("//item/title | //channel/item/title | //*[local-name()='entry']/*[local-name()='title']")
        .map { |n| n.text.to_s.strip.gsub(/\s+/, " ") }
        .reject { |t| t.blank? || t.length < 4 }
      titles
    end

    def extract_keywords_from_titles(titles, limit:)
      count = Hash.new(0)
      titles.each { |title| extract_from_text!(title, count) }
      count.reject! { |kw, _| generic_or_stopword?(kw) }
      count.sort_by { |_, v| -v }.first(limit).map(&:first).uniq
    end

    def extract_from_text!(text, count)
      return if text.blank?

      phrases = text.split(/[,，·‧|｜\-–—:：\s]+/).map(&:strip).reject { |s| s.length < 2 }
      phrases.each do |phrase|
        next if phrase.length > 20
        next if generic_or_stopword?(phrase)
        count[phrase] += 1
      end
      # 단어 단위도 추출 (2~3단어 조합)
      text.split(/\s+/).each do |token|
        next if token.length < 2 || token.length > 12
        next if generic_or_stopword?(token)
        count[token] += 1
      end
    end

    def generic_or_stopword?(kw)
      return true if kw.blank? || kw.length < 2 || kw.length > 20
      return true if kw.match?(/^\d+$/)
      return true if GENERIC_STOPWORDS.include?(kw)
      return true if GENERIC_BLOCKLIST.any? { |b| kw.include?(b) || b.include?(kw) }
      kw.match?(/\A(주식|시장|경제|뉴스|기사|분석|전망)\z/)
    end
  end
end
