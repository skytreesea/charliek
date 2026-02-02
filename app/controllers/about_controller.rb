class AboutController < ApplicationController
  # About 페이지에서는 사이드바가 필요 없으므로 스킵
  skip_before_action :load_sidebar_data
  
  def index
    # 메인화면 설정 로드 (About 페이지용) - 배치 쿼리로 최적화
    settings = Setting.get_all(['home_image_url', 'home_text'])
    @home_image_url = settings['home_image_url'] || ''
    @home_text = settings['home_text'] || '환영합니다! 이 홈페이지는 게시판 기능을 제공합니다.'
    @home_image_record = HomeImage.instance
    
    # 이미지 경로 결정 (Active Storage 우선, 없으면 URL)
    if @home_image_record.image.attached?
      if @home_image_record.image.variable?
        @home_image = @home_image_record.image.variant(resize_to_limit: [800, nil], format: :webp, saver: { quality: 50 })
      else
        @home_image = Rails.application.routes.url_helpers.rails_blob_path(@home_image_record.image, only_path: true)
      end
    elsif @home_image_url.present?
      @home_image = @home_image_url
    else
      @home_image = nil
    end
    
    # Open Graph용 이미지 URL 설정
    if @home_image.present?
      if @home_image.is_a?(ActiveStorage::Variant)
        variant_path = Rails.application.routes.url_helpers.rails_representation_path(@home_image, only_path: true)
        @og_image = "#{request.base_url}#{variant_path}"
      elsif @home_image.is_a?(String)
        if @home_image.start_with?('http://') || @home_image.start_with?('https://')
          @og_image = @home_image
        else
          @og_image = "#{request.base_url}#{@home_image}"
        end
      end
    else
      @og_image = "#{request.base_url}/icon.png"
    end
    
    # SEO: Title 설정
    @page_title = "About | CharlieK"
    
    # SEO: Description 설정
    if @home_text.present?
      cleaned_text = ActionController::Base.helpers.strip_tags(@home_text).gsub(/\s+/, ' ').strip
      @meta_description = cleaned_text.length > 160 ? cleaned_text[0..156] + "..." : cleaned_text
    else
      @meta_description = "Charlie K Archive에 대해 알아보세요."
    end
    
    # Open Graph 메타 태그 설정
    @og_title = "About | CharlieK"
    @og_description = @meta_description
    @og_url = "#{request.base_url}#{request.path}"
  end
end
