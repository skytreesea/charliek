class SitemapController < ApplicationController
  # SEO를 위한 sitemap.xml 생성
  # Google 권장사항: 하나의 sitemap에는 최대 50,000개 URL, 최대 50MB
  # 글 수가 많아지면 sitemap index 구조로 확장 가능
  
  # 불필요한 before_action 스킵 (성능 최적화)
  skip_before_action :load_sidebar_data
  skip_before_action :load_design_settings
  skip_before_action :load_logo
  skip_before_action :track_visit
  skip_before_action :load_visitor_stats
  
  MAX_URLS_PER_SITEMAP = 50_000
  
  def index
    @base_url = request.base_url
    @posts_count = Post.count
    
    # 글 수가 많으면 sitemap index 구조 사용
    if @posts_count > MAX_URLS_PER_SITEMAP
      render :index, content_type: 'application/xml', status: :ok
    else
      # 단일 sitemap (현재는 이 방식 사용)
      @posts = Post.order(updated_at: :desc)
      @categories = Post::CATEGORIES
      render :sitemap, content_type: 'application/xml', status: :ok
    end
  end
  
  # 개별 sitemap (나중에 확장용)
  def sitemap
    @base_url = request.base_url
    page = params[:page].to_i
    per_page = MAX_URLS_PER_SITEMAP
    
    @posts = Post.order(updated_at: :desc)
                 .offset(page * per_page)
                 .limit(per_page)
    @categories = Post::CATEGORIES
    
    render :sitemap, content_type: 'application/xml', status: :ok
  end
end
