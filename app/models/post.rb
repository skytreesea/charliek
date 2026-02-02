class Post < ApplicationRecord
  belongs_to :user, optional: true
  has_many :comments, dependent: :destroy, counter_cache: :comments_count
  has_many :likes, dependent: :destroy
  
  # Active Storage attachment
  has_one_attached :attachment_file

  CATEGORIES = ["주식", "문화", "출판", "Rails", "자유게시판", "생각들"].freeze

  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :slug, presence: true, uniqueness: true, if: -> { respond_to?(:slug) && Post.column_names.include?('slug') }
  validates :slug, exclusion: { in: %w[new edit admin] }, if: -> { respond_to?(:slug) && Post.column_names.include?('slug') }
  validate :attachment_file_size
  validate :attachment_file_type

  scope :recent, -> { where("created_at > ?", 6.hours.ago) }
  scope :by_category, ->(category) { category.present? ? where(category: category) : all }

  # 제목·내용 추출 시 제외할 일반적 단어/구문
  EMERGING_STOPWORDS = %w[
    뉴스 기사 분석 전망 관련 최신 시장 경제 투자 수익 실적 성과
    의 와 과 에 로 를 을 이 가 는 은 도 만 에서 대한 통해
    and or the a an of in on at to for
    정리 요약 소개 소식 발표 공개 예정 가능 전략 포트폴리오
    주식 시장 유가 환율 금리 부동산
  ].freeze

  # 평범한 키워드 블록리스트 (추천에서 완전 제외)
  GENERIC_BLOCKLIST = %w[
    기업실적 기업 실적 주식시장 주식 시장 금리 유가 환율 인플레이션
    글로벌경제 글로벌 경제 국제정세 국제 정세 핵심키워드 핵심 키워드
    최신뉴스 최신 뉴스 사회이슈 사회 이슈 정책 기업실적
  ].freeze

  # 최근 게시글 제목+내용에서 시의성 있는 키워드 추출 (인명, 이슈, 회사명 등)
  def self.emerging_keywords(since: 14.days.ago, limit: 50)
    return [] unless table_exists?

    count = Hash.new(0)

    # 1) 제목에서 추출 (가중치 높음)
    titles = where("created_at >= ? AND title IS NOT NULL AND TRIM(title) != ''", since).pluck(:title)
    titles.each { |title| extract_keywords_from_text!(title.to_s, count, weight: 3) }

    # 2) 내용 앞부분에서 추출 (인명·이슈가 자주 등장)
    contents = where("created_at >= ? AND content IS NOT NULL AND LENGTH(TRIM(content)) > 20", since).pluck(:content)
    contents.each { |content| extract_keywords_from_text!(content.to_s[0, 600], count, weight: 1) }

    # 블록리스트·스탑워드 제거 후 상위 반환
    count.reject! { |kw, _| generic_or_stopword?(kw) }
    count.sort_by { |_, v| -v }.first(limit).map(&:first).uniq
  end

  def self.generic_or_stopword?(kw)
    return true if kw.blank? || kw.length < 2 || kw.length > 20
    return true if kw.match?(/^\d+$/)
    return true if EMERGING_STOPWORDS.include?(kw) || EMERGING_STOPWORDS.include?(kw.downcase)
    return true if GENERIC_BLOCKLIST.any? { |b| kw.include?(b) || b.include?(kw) }
    kw.match?(/\A(주식|시장|경제|뉴스|기사|분석|전망)\z/) || kw.match?(/^(주식|시장|경제)/)
  end

  def self.extract_keywords_from_text!(text, count, weight: 1)
    return if text.blank?

    # 쉼표, ·, | 등으로 구분된 구문 추출
    phrases = text.split(/[,，·‧|｜\-–—:：\n]\s*/).map(&:strip).reject { |s| s.length < 2 }
    phrases.each do |phrase|
      tokens = phrase.split(/\s+/)
      if tokens.size <= 2 && tokens.all? { |t| t.length >= 2 && t.length <= 15 }
        kw = tokens.join(" ")
        next if generic_or_stopword?(kw)
        count[kw] = (count[kw] || 0) + weight
      end
      tokens.each do |t|
        next if generic_or_stopword?(t)
        count[t] = (count[t] || 0) + weight
      end
    end
  end
  
  # slug 자동 생성 (제목 변경 시 또는 slug가 없을 때)
  before_validation :generate_slug, if: -> { respond_to?(:slug) && (slug.blank? || title_changed?) }
  
  # URL 생성 시 slug 사용 (slug가 있으면 사용, 없으면 id)
  # N+1 쿼리 방지: slug가 이미 로드된 경우 추가 쿼리 없이 사용
  def to_param
    return nil unless persisted?
    
    # slug 컬럼이 있는지 확인 (클래스 레벨에서 한 번만 확인하도록 최적화)
    # Rails가 column_names를 캐싱하지만, 추가 최적화를 위해 클래스 변수 사용
    @@has_slug_column ||= (Post.column_names.include?('slug') rescue false)
    
    if @@has_slug_column
      # slug가 이미 로드되어 있으면 바로 사용 (추가 쿼리 없음)
      # slug가 없으면 생성 시도 (단, 사이드바 등에서 호출되는 경우를 고려하여 조건부로만 생성)
      if slug.blank? && title.present? && !@_skip_slug_generation
        generate_slug
        # 사이드바 등 읽기 전용 컨텍스트에서는 DB 업데이트를 하지 않음
        update_column(:slug, slug) if slug.present? && persisted? && !@_skip_slug_generation
      end
      
      slug.present? ? slug : id.to_s
    else
      # slug 컬럼이 없으면 ID 사용
      id.to_s
    end
  end

  def increment_views!
    increment!(:views_count)
  end

  def liked_by?(user)
    return false unless user
    # N+1 쿼리 방지: 이미 eager loaded된 경우 메모리에서 확인
    # loaded?로 확인하여 이미 로드된 경우 any? 사용 (쿼리 없음)
    if likes.loaded?
      # eager loaded된 경우 메모리에서 확인
      likes.any? { |like| like.user_id == user.id }
    else
      # 로드되지 않은 경우에만 DB 쿼리
      likes.exists?(user_id: user.id)
    end
  end
  
  def attachment_file_path
    # Active Storage를 사용하는 경우 URL 반환
    attachment_file.attached? ? Rails.application.routes.url_helpers.rails_blob_path(attachment_file, only_path: true) : nil
  end
  
  private
  
  # slug 생성 메서드 (제목 기반, 한글 지원, 중복 시 -2, -3 등 추가)
  def generate_slug
    return unless respond_to?(:slug) # slug 컬럼이 있는 경우에만
    return if title.blank?
    return if slug.present? && !title_changed? # slug가 이미 있고 제목이 변경되지 않았으면 스킵
    
    # 한글 제목을 slug로 변환 (한글 유지, URL-safe하게 처리)
    base_slug = title.to_s
      .strip                                    # 앞뒤 공백 제거
      .gsub(/\s+/, '-')                         # 연속된 공백을 하이픈으로
      .gsub(/[^\p{Han}\p{Hangul}\p{Alnum}\-]/, '') # 한글, 영문, 숫자, 하이픈만 유지
      .gsub(/\-+/, '-')                         # 연속된 하이픈을 하나로
      .gsub(/^\-|\-$/, '')                      # 앞뒤 하이픈 제거
    
    # 제목이 모두 특수문자이거나 비어있는 경우 처리
    if base_slug.blank?
      if persisted? && id.present?
        base_slug = "post-#{id}"
      else
        # 새 레코드인 경우 타임스탬프 사용
        base_slug = "post-#{Time.current.to_i}"
      end
    end
    
    candidate_slug = base_slug
    counter = 1
    
    # 중복 체크 (자기 자신 제외)
    query = Post.where(slug: candidate_slug)
    query = query.where.not(id: id) if persisted? && id.present?
    
    while query.exists?
      counter += 1
      candidate_slug = "#{base_slug}-#{counter}"
      query = Post.where(slug: candidate_slug)
      query = query.where.not(id: id) if persisted? && id.present?
    end
    
    self.slug = candidate_slug
  end
  
  def attachment_file_size
    if attachment_file.attached? && attachment_file.byte_size > 10.megabytes
      errors.add(:attachment_file, "파일 크기는 최대 10MB까지 업로드 가능합니다.")
    end
  end
  
  def attachment_file_type
    allowed_types = [
      'application/pdf',
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/gif',
      'image/webp'
    ]
    if attachment_file.attached? && !attachment_file.content_type.in?(allowed_types)
      errors.add(:attachment_file, "이미지 파일(jpg, png, gif, webp) 또는 PDF 파일만 업로드 가능합니다.")
    end
  end
end

