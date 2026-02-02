# Google AdSense ads.txt 파일 서빙 컨트롤러
# public/ads.txt가 서빙되지 않는 경우를 대비한 안전장치
class AdsTxtController < ActionController::Base
  # CSRF 및 Host authorization 제외 (ads.txt는 모든 도메인에서 접근 가능해야 함)
  skip_before_action :verify_authenticity_token, raise: false
  
  # Rails 7+ host authorization 우회
  if Rails::VERSION::MAJOR >= 7 && respond_to?(:skip_before_action)
    skip_before_action :check_host_authorization, raise: false
  end
  
  def show
    ads_txt_path = Rails.root.join('public', 'ads.txt')
    
    if File.exist?(ads_txt_path)
      content = File.read(ads_txt_path)
      render plain: content,
        content_type: 'text/plain; charset=utf-8',
        status: :ok
    else
      head :not_found
    end
  end
end
