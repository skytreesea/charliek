class LogoImage < ApplicationRecord
  has_one_attached :image
  
  # 싱글톤 패턴으로 사용
  def self.instance
    first_or_create!
  end
  
  # 로고 이미지 URL 가져오기 (캐싱 적용)
  def self.image_url
    Rails.cache.fetch('logo_image_url', expires_in: 1.hour) do
      logo = instance
      if logo.image.attached?
        Rails.application.routes.url_helpers.rails_blob_path(logo.image, only_path: true)
      else
        nil
      end
    end
  end
  
  # 로고 이미지가 업데이트되면 캐시 무효화
  after_commit :clear_logo_cache, on: [:create, :update, :destroy]
  
  private
  
  def clear_logo_cache
    Rails.cache.delete('logo_image_url')
  end
end
