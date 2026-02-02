class Setting < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  
  # 설정이 변경되면 관련 캐시 무효화
  after_commit :clear_setting_cache, on: [:create, :update, :destroy]

  # 설정 값 가져오기 (캐싱 적용)
  def self.get(key, default = nil)
    Rails.cache.fetch("setting_#{key}", expires_in: 1.hour) do
      setting = find_by(key: key)
      setting ? setting.value : default
    end
  end

  # 설정 값 설정하기 (캐시 무효화 포함)
  def self.set(key, value)
    setting = find_or_initialize_by(key: key)
    setting.value = value.to_s
    result = setting.save
    if result
      # 캐시 무효화 (after_commit에서도 처리되지만 명시적으로 처리)
      Rails.cache.delete("setting_#{key}")
      # 배치 캐시도 무효화 (모든 배치 캐시 키 패턴 삭제는 비효율적이므로 개별 키만 삭제)
    else
      Rails.logger.error "Setting.save failed for key: #{key}, errors: #{setting.errors.full_messages.join(', ')}"
    end
    result
  end

  # 여러 설정 한번에 가져오기 (캐싱 적용)
  def self.get_all(keys)
    # 키를 정렬하여 캐시 키 일관성 유지
    sorted_keys = keys.sort
    cache_key = "settings_batch_#{sorted_keys.join('_')}"
    
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      where(key: keys).pluck(:key, :value).to_h
    end
  end
  
  private
  
  def clear_setting_cache
    # 개별 설정 캐시 무효화
    Rails.cache.delete("setting_#{key}")
    # 배치 캐시는 키가 변경될 수 있으므로 무효화하지 않음 (1시간 TTL로 자동 만료)
  end
end
