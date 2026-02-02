class Admin::HomeController < ApplicationController
  before_action :authenticate_user!
  before_action :check_super_admin

  def index
    @home_image = HomeImage.instance
    @logo_image = LogoImage.instance
    @home_settings = {
      image_url: Setting.get('home_image_url', ''),
      text: Setting.get('home_text', '환영합니다! 이 홈페이지는 게시판 기능을 제공합니다.')
    }
  end

  def update
    begin
      Rails.logger.info "=== Home Settings Update Started ==="
      Rails.logger.info "Raw params keys: #{params.keys.inspect}"
      Rails.logger.info "Params[:home]: #{params[:home].inspect}" if params[:home]
      
      # Strong Parameters 사용
      begin
        home_params = params.require(:home).permit(:image_url, :text, :image_file, :logo_file)
      rescue ActionController::ParameterMissing => e
        Rails.logger.error "Parameter missing: #{e.message}"
        redirect_to "/admin/home", alert: "잘못된 요청입니다."
        return
      end
      
      Rails.logger.info "Home params keys: #{home_params.keys.inspect}"
      Rails.logger.info "Image file present?: #{home_params[:image_file].present?}"
      Rails.logger.info "Logo file present?: #{home_params[:logo_file].present?}"
      Rails.logger.info "Image file class: #{home_params[:image_file].class}" if home_params[:image_file]
      
      # 로고 이미지 파일 업로드 처리
      if home_params[:logo_file].present?
        @logo_image = LogoImage.instance
        @logo_image.image.attach(home_params[:logo_file])
        # 캐시 무효화 (after_commit에서도 처리되지만 명시적으로 처리)
        Rails.cache.delete('logo_image_url')
        Rails.logger.info "=== Logo upload completed successfully ==="
      end
      
      # 이미지 파일 업로드가 있으면 우선 처리
      if home_params[:image_file].present?
        @home_image = HomeImage.instance
        @home_image.image.attach(home_params[:image_file])
        Setting.set('home_image_url', '') # URL은 비움
        Rails.logger.info "=== Image upload completed successfully ==="
      elsif home_params[:image_url].present? && home_params[:image_url].strip.present?
        # 이미지 URL 저장
        Setting.set('home_image_url', home_params[:image_url].strip)
        # Active Storage 이미지가 있으면 삭제
        @home_image = HomeImage.instance
        @home_image.image.purge if @home_image.image.attached?
        Rails.logger.debug "Saved image URL: #{home_params[:image_url].strip}"
      end
      
      # 텍스트 저장
      if home_params[:text].present?
        Setting.set('home_text', home_params[:text])
        Rails.logger.debug "Saved text: #{home_params[:text][0..50]}..."
      end
      
      redirect_to "/admin/home", notice: "메인화면 설정이 업데이트되었습니다."
    rescue => e
      Rails.logger.error "Update error: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      redirect_to "/admin/home", alert: "설정 업데이트 중 오류가 발생했습니다: #{e.message}"
    end
  end

  private

  def check_super_admin
    unless current_user&.super_admin?
      redirect_to "/", alert: "수퍼관리자만 접근할 수 있습니다.", status: :forbidden
    end
  end
end
