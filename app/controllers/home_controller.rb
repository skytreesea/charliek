class HomeController < ApplicationController
  def index
    # 인기글 4개 가져오기
    @popular_posts = Post.includes(:user, :comments)
                         .order(views_count: :desc)
                         .limit(4)
    
    # 최신글 4개 가져오기
    @recent_posts = Post.includes(:user, :comments)
                        .order(created_at: :desc)
                        .limit(4)
    
    # 홈 화면 카드 뉴스: 이미지가 있는 모든 게시글, 왼쪽부터 최신순
    # Active Storage 이미지 또는 content 내 img 태그가 있는 Post만 조회
    all_posts = Post.includes(:user)
                    .with_attached_attachment_file
                    .order(created_at: :desc)
                    .limit(100) # 충분한 수를 가져온 후 필터링
    
    @stock_posts = all_posts.select do |post|
      has_image = false
      if post.attachment_file.attached?
        has_image = post.attachment_file.content_type&.start_with?('image/')
      end
      unless has_image
        img_match = post.content.to_s.match(/<img[^>]+src=["']([^"']+)["']/i)
        has_image = img_match.present? && img_match[1].present?
      end
      has_image
    end
    
    # SEO: Title 설정
    @page_title = "CharlieK"
    
    # SEO: Description 설정
    @meta_description = "최신 주식 뉴스와 정보를 확인하세요. Charlie K Archive에서 다양한 콘텐츠를 만나보세요."
    
    # Open Graph 메타 태그 설정
    @og_title = "Charlie K - 주식 뉴스"
    @og_description = @meta_description
    @og_url = "#{request.base_url}#{request.path}"
    @og_image = "#{request.base_url}/icon.png"
  end
end
