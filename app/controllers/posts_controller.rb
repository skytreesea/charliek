class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :show_by_id]
  before_action :set_post, only: %i[ show edit update destroy admin_destroy like unlike ]
  before_action :check_admin, only: [:admin_destroy]
  
  # 쿼리 카운터 (개발 환경에서만)
  around_action :count_queries, only: [:show], if: -> { Rails.env.development? }

  # GET /posts or /posts.json
  def index
    # URL 파라미터 디코딩 및 정규화
    category_param = params[:category].presence
    if category_param
      # URL 인코딩된 한글을 디코딩
      category_param = CGI.unescape(category_param) if category_param.include?('%')
      # 유니코드 정규화(NFC) 및 공백 제거
      category_param = category_param.unicode_normalize(:nfc).strip
    end
    @category = category_param || "주식"
    
    # CATEGORIES 배열 내 값과 정확히 일치하도록 매핑 (인코딩/공백 차이 극복)
    matched_category = Post::CATEGORIES.find { |c| c.unicode_normalize(:nfc) == @category }
    @category = matched_category if matched_category
    
    # SEO: Title 설정 (카테고리 | CharlieK)
    @page_title = "#{@category} | CharlieK"
    
    # SEO: Description 설정
    @meta_description = "#{@category} 카테고리의 게시글 목록입니다. 최신 글과 인기 글을 확인하세요."
    
    # Open Graph 메타 태그 설정
    @og_title = "#{@category} | CharlieK"
    @og_description = @meta_description
    @og_url = "#{request.base_url}#{request.path}"
    @og_image = "#{request.base_url}/icon.png"
    
    # 카테고리별 게시글 조회
    # 기존 게시글 중 카테고리가 NULL이거나 빈 값인 경우도 포함
    # "주식/경제" 같은 이전 카테고리도 "주식"으로 매핑
    if Post::CATEGORIES.include?(@category)
      # 유효한 카테고리: 해당 카테고리만 조회
      if @category == "주식"
        # "주식" 카테고리는 "주식/경제"도 포함하고, NULL이나 빈 문자열도 포함 (기존 게시글 호환성)
        posts_scope = Post.where("category = ? OR category IS NULL OR category = '' OR category LIKE ?", @category, "주식%")
      else
        # 다른 카테고리(문화, 출판, Rails 등)는 정확히 해당 카테고리만 조회
        # 서버 환경 호환성을 위해 여러 방법 시도 (TRIM, 정확한 매칭, Ruby 레벨 필터링)
        
        # 방법 1: 정확한 매칭 시도
        posts_scope = Post.where(category: @category)
        count_method1 = posts_scope.count
        
        # 방법 2: TRIM 사용 (SQLite 호환)
        if count_method1 == 0
          begin
            posts_scope = Post.where("TRIM(category) = ?", @category)
            count_method2 = posts_scope.count
            if count_method2 == 0
              # 방법 3: Ruby 레벨에서 정규화 후 필터링 (최종 폴백)
              all_posts = Post.all.to_a
              normalized_target = @category.unicode_normalize(:nfc).strip
              posts_scope = Post.where(id: all_posts.select { |p| 
                cat = p.category.to_s.unicode_normalize(:nfc).strip
                cat == normalized_target
              }.map(&:id))
            end
          rescue => e
            # TRIM이 실패하면 Ruby 레벨 필터링으로 폴백
            Rails.logger.warn "TRIM query failed: #{e.message}, using Ruby-level filtering"
            all_posts = Post.all.to_a
            normalized_target = @category.unicode_normalize(:nfc).strip
            posts_scope = Post.where(id: all_posts.select { |p| 
              cat = p.category.to_s.unicode_normalize(:nfc).strip
              cat == normalized_target
            }.map(&:id))
          end
        end
        
        # 디버깅: 문화 카테고리 쿼리 확인 (프로덕션에서도 출력)
        if @category == "문화"
          Rails.logger.info "=== 문화 카테고리 디버깅 (환경: #{Rails.env}) ==="
          Rails.logger.info "Category param (raw): #{params[:category].inspect}"
          Rails.logger.info "Selected category: #{@category.inspect}"
          Rails.logger.info "Category bytes: #{@category.bytes.inspect}"
          
          # 실제 데이터베이스에 있는 카테고리 확인
          all_categories = Post.distinct.pluck(:category).compact.sort
          Rails.logger.info "All categories in DB: #{all_categories.inspect}"
          Rails.logger.info "문화 카테고리 게시글 수 (정확한 매칭): #{Post.where(category: '문화').count}"
          Rails.logger.info "문화 카테고리 게시글 수 (TRIM): #{Post.where('TRIM(category) = ?', '문화').count rescue 'N/A'}"
          Rails.logger.info "최종 posts_scope count: #{posts_scope.count}"
          Rails.logger.info "최종 posts_scope SQL: #{posts_scope.to_sql}"
        end
      end
    elsif @category.blank?
      # 카테고리가 없으면 전체 조회
      posts_scope = Post.all
    else
      # CATEGORIES 배열에는 없지만 DB에 존재할 수 있으므로 시도
      posts_scope = Post.where(category: @category)
      
      # 결과가 없으면 TRIM 시도
      if posts_scope.count == 0
        begin
          posts_scope = Post.where("TRIM(category) = ?", @category)
        rescue => e
          Rails.logger.warn "TRIM query failed for category #{@category.inspect}: #{e.message}"
        end
      end
      
      # 여전히 결과가 없으면 전체 조회로 폴백
      if posts_scope.count == 0
        Rails.logger.warn "Invalid category: #{@category.inspect}, showing all posts"
        posts_scope = Post.all
      end
    end
    
    # Eager loading과 정렬 (N+1 문제 해결)
    # user: 작성자 정보
    # comments: comments_count가 없을 경우를 대비해 로드 (nested: user도 함께 로드)
    # attachment_file: 이미지 썸네일 표시용
    posts_scope = posts_scope.includes(:user, comments: :user)
                             .with_attached_attachment_file
                             .order(created_at: :desc)
    
    # Pagy 43.x 방식: offset 사용
    begin
      @pagy, @posts = pagy(:offset, posts_scope, limit: 20)
    rescue => e
      # Pagy 오류 발생 시 전체 조회로 폴백
      Rails.logger.error "Pagy error: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      posts_scope = Post.all.includes(:user)
                        .with_attached_attachment_file
                        .order(created_at: :desc)
      @pagy, @posts = pagy(:offset, posts_scope, limit: 20)
    end
    
    # 디버깅 로그 (프로덕션에서도 문화 카테고리는 출력)
    if Rails.env.development? || @category == "문화"
      Rails.logger.info "=== Posts Index Debug (환경: #{Rails.env}) ==="
      Rails.logger.info "Request category param: #{params[:category].inspect}"
      Rails.logger.info "Selected category: #{@category.inspect}"
      Rails.logger.info "Category in CATEGORIES: #{Post::CATEGORIES.include?(@category)}"
      Rails.logger.info "Posts scope SQL: #{posts_scope.to_sql}" if defined?(posts_scope)
      Rails.logger.info "Posts after pagy: #{@posts.size}"
      Rails.logger.info "Pagy page: #{@pagy.page}, Pagy count: #{@pagy.count}, Pagy pages: #{@pagy.pages}"
      
      # 실제 데이터베이스에 있는 카테고리 확인
      if @category == "문화"
        db_categories = Post.distinct.pluck(:category).compact.sort
        culture_posts_count = Post.where(category: "문화").count
        Rails.logger.info "=== 문화 카테고리 상세 디버깅 ==="
        Rails.logger.info "All categories in DB: #{db_categories.inspect}"
        Rails.logger.info "문화 카테고리 게시글 수 (정확한 매칭): #{culture_posts_count}"
        Rails.logger.info "문화 카테고리 게시글 ID 목록: #{Post.where(category: '문화').pluck(:id, :title).inspect}"
      end
    end
  end

  # GET /posts/:slug (slug 기반)
  def show
    @post.increment_views!
    
    # Eager Loading 강화: 댓글, 댓글 작성자, 좋아요 유저를 한 번에 메모리로 로드
    # set_post에서 이미 eager load되었지만, 명시적으로 재확인하여 모든 연관 데이터가 메모리에 로드되도록 보장
    # association이 로드되지 않은 경우에만 재로드 (추가 쿼리 방지)
    begin
      user_loaded = @post.association(:user).loaded?
      comments_loaded = @post.association(:comments).loaded?
      likes_loaded = @post.association(:likes).loaded?
      
      unless user_loaded && comments_loaded && likes_loaded
        # 혹시 모를 경우를 대비해 모든 연관 데이터를 한 번에 eager load
        @post = Post.includes(:user, comments: :user, likes: :user)
                    .with_attached_attachment_file
                    .find(@post.id)
      end
    rescue => e
      # association 메서드가 실패하는 경우를 대비해 안전하게 처리
      Rails.logger.warn "Association check failed: #{e.message}"
      # 안전하게 재로드
      @post = Post.includes(:user, comments: :user, likes: :user)
                  .with_attached_attachment_file
                  .find(@post.id)
    end
    
    # 댓글 정렬: 이미 로드된 경우 메모리에서 정렬 (추가 쿼리 없음)
    if @post.comments.loaded?
      # 이미 로드된 경우 메모리에서 정렬 (추가 쿼리 없음)
      @post_comments = @post.comments.sort_by(&:created_at).reverse
    else
      # 혹시 모를 경우를 대비해 eager load 후 정렬 (comments의 user도 함께 로드)
      @post_comments = @post.comments.includes(:user).order(created_at: :desc).to_a
    end
    @comments_count = @post_comments.size # 이미 로드된 배열의 길이 사용 (쿼리 없음)
    @comment = Comment.new
    
    # 관련 글 조회: 같은 카테고리에서 현재 글을 제외하고 조회수가 높은 글 3개
    # N+1 쿼리 방지: user와 attachment_file을 eager load
    related_category = @post.category.presence || "주식"
    @related_posts = Post.where.not(id: @post.id)
                          .where("category = ? OR (category IS NULL AND ? = '주식') OR (category = '' AND ? = '주식')", related_category, related_category, related_category)
                          .includes(:user)
                          .with_attached_attachment_file
                          .order(views_count: :desc)
                          .limit(3)
    
    # SEO: Title 설정 (글제목 | CharlieK)
    @page_title = "#{@post.title} | CharlieK"
    
    # SEO: Description 설정 (본문 앞 120~160자 요약, 공백 정리)
    # GC 최적화: 문자열 조작을 최소화하고 한 번에 처리
    description = ActionController::Base.helpers.strip_tags(@post.content.to_s)
    if description.present?
      # 공백 정리 (연속된 공백을 하나로, 줄바꿈 제거) - 한 번에 처리
      cleaned_description = description.gsub(/\s+/, ' ').strip
      # 120~160자 사이로 조정 (단어 중간에서 끊기지 않도록)
      desc_length = cleaned_description.length
      @meta_description = if desc_length > 160
        cleaned_description[0..156] + "..."
      elsif desc_length > 120
        cleaned_description
      else
        cleaned_description
      end
    else
      @meta_description = "Charlie K 게시물"
    end
    
    # Open Graph 메타 태그 설정
    @og_title = @post.title
    @og_url = "#{request.base_url}#{request.path}"
    @og_type = "article"  # 게시물이므로 article 타입 사용
    @og_description = @meta_description
    
    # Article 메타 태그 (선택사항)
    @article_published_time = @post.created_at.iso8601
    @article_author = @post.user&.display_name || "익명"
    @article_section = @post.category
    
    # 이미지 설정: 첨부된 이미지가 있으면 우선 사용 (variant 사용하여 최적화)
    # 중복 요청 방지 및 GC 최적화: variant와 경로를 한 번만 생성하고 재사용
    @post_image_variant = nil
    @post_image_blob_path = nil
    
    # GC 최적화: attachment_file을 한 번만 접근
    attachment_file = @post.attachment_file if @post.attachment_file.attached?
    
    if attachment_file&.content_type&.start_with?('image/')
      # Active Storage blob의 절대 URL 생성 (variant 사용)
      if attachment_file.variable?
        # variant를 한 번만 생성하고 재사용 (중복 요청 방지 및 GC 최적화)
        @post_image_variant = attachment_file.variant(resize_to_limit: [800, nil], format: :webp, saver: { quality: 50 })
        variant_path = Rails.application.routes.url_helpers.rails_representation_path(@post_image_variant, only_path: true)
        @og_image = "#{request.base_url}#{variant_path}"
      else
        # blob_path도 한 번만 생성하고 재사용
        @post_image_blob_path = Rails.application.routes.url_helpers.rails_blob_path(attachment_file, only_path: true)
        @og_image = "#{request.base_url}#{@post_image_blob_path}"
      end
    else
      # 게시물 내용에서 첫 번째 이미지 태그 추출 시도
      # GC 최적화: content를 한 번만 변환
      content_str = @post.content.to_s
      img_match = content_str.match(/<img[^>]+src=["']([^"']+)["']/i)
      if img_match && img_match[1].present?
        img_src = img_match[1]
        # 절대 URL인지 확인 (GC 최적화: start_with? 체인 최소화)
        if img_src.start_with?('http://', 'https://')
          @og_image = img_src
        elsif img_src.start_with?('/')
          # 절대 경로인 경우 (예: /rails/active_storage/blobs/...)
          @og_image = "#{request.base_url}#{img_src}"
        else
          # 상대 경로인 경우
          @og_image = "#{request.base_url}/#{img_src}"
        end
      else
        # 기본 이미지 사용
        @og_image = "#{request.base_url}/icon.png"
      end
    end
  end

  # GET /posts/new
  def new
    @post = Post.new
    @post.category = params[:category] || "주식"
  end

  # GET /posts/1/edit
  def edit
    # 카테고리가 NULL이면 기본값 설정
    @post.category ||= "주식"
  end

  # POST /posts or /posts.json
  def create
    @post = current_user.posts.build(post_params)

    respond_to do |format|
      if @post.save
        format.html { redirect_to post_path(@post), notice: "게시글이 성공적으로 작성되었습니다." }
        format.json { render :show, status: :created, location: @post }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /posts/:slug
  def update
    respond_to do |format|
      if @post.update(post_params)
        format.html { redirect_to post_path(@post), notice: "게시글이 성공적으로 수정되었습니다." }
        format.json { render :show, status: :ok, location: @post }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  rescue => e
    Rails.logger.error "Update error: #{e.message}"
    Rails.logger.error e.backtrace.first(10).join("\n")
    raise
  end

  # DELETE /posts/:slug or /posts/:slug.json
  def destroy
    unless @post.user == current_user
      redirect_to @post, alert: "자신의 글만 삭제할 수 있습니다.", status: :forbidden
      return
    end

    category = @post.category.presence || "주식"
    @post.destroy!

    respond_to do |format|
      format.html { redirect_to "/posts?category=#{CGI.escape(category)}", notice: "게시글이 삭제되었습니다.", status: :see_other }
      format.json { head :no_content }
    end
  end

  # DELETE /posts/:slug/admin_destroy (운영자 전용)
  def admin_destroy
    category = @post.category.presence || "주식"
    @post.destroy!

    respond_to do |format|
      format.html { redirect_to "/posts?category=#{CGI.escape(category)}", notice: "게시글이 삭제되었습니다.", status: :see_other }
      format.json { head :no_content }
    end
  end

  # POST /posts/:slug/like
  def like
    unless @post.liked_by?(current_user)
      like = @post.likes.build(user: current_user)
      if like.save
        @post.increment!(:likes_count)
        redirect_to post_path(@post), notice: "좋아요를 눌렀습니다."
      else
        redirect_to post_path(@post), alert: "좋아요 처리에 실패했습니다."
      end
    else
      redirect_to post_path(@post), alert: "이미 좋아요를 눌렀습니다."
    end
  end

  # DELETE /posts/:slug/unlike
  def unlike
    # N+1 쿼리 방지: 이미 eager loaded된 경우 메모리에서 찾기
    like = if @post.likes.loaded?
      @post.likes.find { |l| l.user_id == current_user.id }
    else
      @post.likes.find_by(user: current_user)
    end
    
    if like&.destroy
      @post.decrement!(:likes_count)
      redirect_to post_path(@post), notice: "좋아요를 취소했습니다."
    else
      redirect_to post_path(@post), alert: "좋아요 취소에 실패했습니다."
    end
  end

  # GET /posts/:id/show (기존 ID 기반 접근 - 301 리다이렉트)
  def show_by_id
    @post = Post.find(params[:id])
    redirect_to post_path(@post), status: :moved_permanently
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    # params[:slug] 또는 params[:id] 모두 처리 (slug 우선, 없으면 ID로 시도)
    def set_post
      identifier = params[:slug] || params[:id]
      return unless identifier.present?
      
      # 'new', 'edit', 'admin' 등 예약어는 조기에 리턴
      return if identifier == 'new' || identifier == 'edit' || identifier == 'admin'
      
      # slug 컬럼이 있는지 확인
      has_slug_column = Post.column_names.include?('slug')
      
      # slug로 먼저 시도 (slug 컬럼이 있고, 숫자가 아닌 경우)
      # N+1 쿼리 방지를 위해 user, comments, likes를 모두 eager load
      if has_slug_column && !identifier.match?(/^\d+$/)
        @post = Post.includes(:user, comments: :user, likes: :user).with_attached_attachment_file.find_by(slug: identifier)
      end
      
      # slug로 찾지 못했거나 slug 컬럼이 없는 경우 ID로 시도 (find_by 사용으로 안전하게)
      # 숫자인 경우 정수로 변환해서 찾기
      if identifier.match?(/^\d+$/)
        @post ||= Post.includes(:user, comments: :user, likes: :user).with_attached_attachment_file.find_by(id: identifier.to_i)
      else
        @post ||= Post.includes(:user, comments: :user, likes: :user).with_attached_attachment_file.find_by(id: identifier)
      end
      
      # 최종적으로 찾지 못한 경우 에러 발생
      raise ActiveRecord::RecordNotFound, "Couldn't find Post with identifier=#{identifier.inspect}" unless @post
      
      # ID로 찾았는데 slug가 있으면 slug URL로 리다이렉트 (SEO 최적화)
      if has_slug_column && @post.respond_to?(:slug) && @post.slug.present? && identifier != @post.slug
        redirect_to post_path(@post), status: :moved_permanently
        return
      end
    end

    # 쿼리 카운터 (개발 환경에서만)
    def count_queries
      query_count = 0
      callback = lambda do |name, start, finish, id, payload|
        query_count += 1 unless payload[:name] == 'SCHEMA' || payload[:cached]
      end
      
      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
        yield
      end
      
      if Rails.env.development?
        Rails.logger.info "=== PostsController#show Query Count ==="
        Rails.logger.info "Total SQL queries executed: #{query_count}"
        Rails.logger.info "Post ID: #{@post&.id}, Slug: #{@post&.slug}"
        Rails.logger.info "Comments count: #{@comments_count || 0}"
        Rails.logger.info "Related posts count: #{@related_posts&.size || 0}"
      end
    end

    # Only allow a list of trusted parameters through.
    def post_params
      params.require(:post).permit(:title, :content, :category, :attachment_file)
    end

    def check_admin
      unless current_user&.admin?
        redirect_to "/posts", alert: "운영자만 접근할 수 있습니다.", status: :forbidden
      end
    end
end
