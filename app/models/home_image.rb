class HomeImage < ApplicationRecord
  has_one_attached :image
  
  # 싱글톤 패턴으로 사용 (캐싱 적용)
  def self.instance
    Rails.cache.fetch('home_image_instance', expires_in: 1.hour) do
      first_or_create!
    end
  end
  
  def self.image_url
    instance.image.attached? ? Rails.application.routes.url_helpers.rails_blob_path(instance.image, only_path: true) : nil
  end
  
  # 이미지가 업데이트되면 캐시 무효화
  after_commit :clear_home_image_cache, on: [:create, :update, :destroy]
  
  private
  
  def clear_home_image_cache
    Rails.cache.delete('home_image_instance')
  end
end
