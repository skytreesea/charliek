# 기사생성기 전용 헬퍼
module ArticlesHelper
  # 추천 키워드: 당일 최초 호출 시 DB에 저장, 이후 해당 날짜에는 shuffle하여 제시
  def recommended_keywords
    record = DailyRecommendedKeyword.find_or_build_for_today
    record.shuffled_keywords
  end

  # 키워드 문자열을 개별 키워드 배열로 파싱 (쉼표 구분)
  def keyword_list(keywords_str)
    return [] if keywords_str.blank?
    keywords_str.to_s.split(/,/).map(&:strip).reject(&:blank?).uniq
  end

  # 키워드 개수 검증: 2~6개
  def keyword_count_valid?(keywords_str)
    list = keyword_list(keywords_str)
    list.size >= 2 && list.size <= 6
  end
end
