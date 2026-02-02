class ApplicationController < ActionController::Base
  include Pagy::Method

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Canonical Domain 리다이렉트 (ApplicationController 레벨에서도 처리)
  before_action :redirect_to_canonical_domain, if: -> { Rails.env.production? }
  
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :load_sidebar_data, unless: :devise_controller?
  before_action :load_design_settings, unless: :devise_controller?
  before_action :load_logo, unless: :devise_controller?
  before_action :track_visit, unless: :devise_controller?
  before_action :load_visitor_stats, if: -> { user_signed_in? && current_user&.admin? }

  protected

  def redirect_to_canonical_domain
    # 미들웨어에서 이미 처리되었을 수 있지만, 이중 체크
    return if request.host == 'www.charliek.kr'
    
    if request.host == 'charliek.kr'
      redirect_to "#{request.protocol}www.charliek.kr#{request.fullpath}", status: :moved_permanently
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:nickname])
    devise_parameter_sanitizer.permit(:account_update, keys: [:nickname])
  end

  def load_sidebar_data
    return unless defined?(Post) && Post.table_exists?
    
    # 캐시 키 생성: 최신 글의 ID와 생성 시간을 포함하여 새로운 글이 추가되면 자동으로 무효화
    # 단일 쿼리로 최신 ID와 업데이트 시간을 함께 가져오기
    latest_post = Post.select(:id, :updated_at).order(id: :desc).limit(1).first
    latest_post_id = latest_post&.id || 0
    latest_post_updated_at = latest_post&.updated_at&.to_i || 0
    cache_key = "sidebar_data_#{latest_post_id}_#{latest_post_updated_at}"
    
    cached_data = Rails.cache.fetch(cache_key, expires_in: 15.minutes) do
      # N+1 쿼리 방지: user와 slug를 함께 eager load
      # slug는 to_param에서 사용되므로 미리 로드하여 추가 쿼리 방지
      recent_posts = Post.includes(:user)
                         .select(:id, :title, :slug, :created_at, :views_count, :user_id)
                         .order(created_at: :desc)
                         .limit(5)
                         .to_a
      
      popular_posts = Post.includes(:user)
                          .select(:id, :title, :slug, :created_at, :views_count, :user_id)
                          .order(views_count: :desc)
                          .limit(3)
                          .to_a
      
      {
        recent_posts: recent_posts,
        popular_posts: popular_posts
      }
    end
    
    @recent_posts = cached_data[:recent_posts]
    @popular_posts = cached_data[:popular_posts]
  rescue => e
    # Ignore errors if Post model is not available or table doesn't exist
    @recent_posts = []
    @popular_posts = []
  end

  def load_design_settings
    # 기본값 먼저 설정
    default_colors = {
      bg: '#FAF9F6',
      card: '#FFFFFF',
      primary: '#D4A373',
      text: '#433E3F',
      border: 'rgba(212, 163, 115, 0.2)',
      hover: 'rgba(212, 163, 115, 0.15)'
    }
    
    default_fonts = {
      heading: 'system-ui, sans-serif',
      body: 'system-ui, sans-serif',
      button: 'system-ui, sans-serif',
      link: 'system-ui, sans-serif',
      nav: 'system-ui, sans-serif',
      code: "'Courier New', monospace",
      footer: 'system-ui, sans-serif'
    }
    
    @font_urls = []
    
    # 데이터베이스에서 설정 로드 시도 (배치 쿼리로 최적화)
    if defined?(Setting) && Setting.table_exists?
      begin
        # 모든 설정 키를 한 번에 가져오기 (N+1 쿼리 방지)
        setting_keys = [
          'theme_bg', 'theme_card', 'theme_primary', 'theme_text', 'theme_border', 'theme_hover',
          'font_heading', 'font_body', 'font_button', 'font_link', 'font_nav', 'font_code', 'font_footer'
        ]
        settings_hash = Setting.get_all(setting_keys)
        
        @theme_colors = {
          bg: settings_hash['theme_bg'] || default_colors[:bg],
          card: settings_hash['theme_card'] || default_colors[:card],
          primary: settings_hash['theme_primary'] || default_colors[:primary],
          text: settings_hash['theme_text'] || default_colors[:text],
          border: settings_hash['theme_border'] || default_colors[:border],
          hover: settings_hash['theme_hover'] || default_colors[:hover]
        }
        
        @theme_fonts = {
          heading: settings_hash['font_heading'] || default_fonts[:heading],
          body: settings_hash['font_body'] || default_fonts[:body],
          button: settings_hash['font_button'] || default_fonts[:button],
          link: settings_hash['font_link'] || default_fonts[:link],
          nav: settings_hash['font_nav'] || default_fonts[:nav],
          code: settings_hash['font_code'] || default_fonts[:code],
          footer: settings_hash['font_footer'] || default_fonts[:footer]
        }
        
        # 사용 중인 폰트 URL 수집
        font_mapping = {
          'Noto Sans KR' => 'https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;500;600;700&display=swap',
          'Nanum Gothic' => 'https://fonts.googleapis.com/css2?family=Nanum+Gothic:wght@400;700;800&display=swap',
          'Nanum Myeongjo' => 'https://fonts.googleapis.com/css2?family=Nanum+Myeongjo:wght@400;700;800&display=swap',
          'Do Hyeon' => 'https://fonts.googleapis.com/css2?family=Do+Hyeon&display=swap',
          'Jua' => 'https://fonts.googleapis.com/css2?family=Jua&display=swap'
        }
        
        @theme_fonts.each_value do |font_value|
          font_mapping.each do |font_name, url|
            if font_value.present? && font_value.include?(font_name) && !@font_urls.include?(url)
              @font_urls << url
            end
          end
        end
      rescue => e
        # 에러 발생 시 기본값 유지
        Rails.logger.error "Design settings load error: #{e.message}"
      end
    end
  end

  def track_visit
    return unless defined?(Visit) && Visit.table_exists?
    
    # 방문 기록 (에러가 발생해도 메인 요청에는 영향 없음)
    begin
      ip_address = request.remote_ip || request.ip
      user_agent = request.user_agent
      
      # 동기적으로 처리하되, 에러는 무시
      Visit.record_visit(ip_address, user_agent)
    rescue => e
      # 방문 추적 실패는 로그만 남기고 계속 진행
      Rails.logger.error "Visit tracking error: #{e.message}"
    end
  end
  
  def load_logo
    return unless defined?(LogoImage) && LogoImage.table_exists?
    
    # 로고 이미지 URL 로드 (캐싱됨, 업로드된 이미지가 있으면 사용, 없으면 기본 아이콘)
    @logo_url = LogoImage.image_url || '/icon.png'
  rescue => e
    Rails.logger.error "Logo load error: #{e.message}" if Rails.env.development?
    @logo_url = '/icon.png'
  end
  
  def load_visitor_stats
    return unless defined?(Visit) && Visit.table_exists?
    
    # 고유 방문자 수 사용 (누적 전체 사용자 수)
    @total_visits = Visit.total_unique_visitors
    @daily_visits = Visit.daily_unique_visitors(Date.today)
  rescue => e
    @total_visits = 0
    @daily_visits = 0
  end

  # Devise 헬퍼 메서드들을 뷰에서 사용할 수 있도록 선언
  helper_method :current_user, :user_signed_in?
end
