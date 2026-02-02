# Canonical Domain Redirect Middleware
# charliek.kr -> www.charliek.kr 리다이렉트 처리
# production 환경에서만 작동하며, 정적 파일(ads.txt 포함)도 처리합니다.

class CanonicalDomainMiddleware
  CANONICAL_HOST = 'www.charliek.kr'.freeze
  
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    path = request.path
    host = request.host
    
    # 프로덕션 환경이 아니면 그대로 진행
    return @app.call(env) unless Rails.env.production?
    
    # www.charliek.kr이면 그대로 진행
    return @app.call(env) if host == CANONICAL_HOST
    
    # charliek.kr로 들어오는 모든 요청을 www.charliek.kr로 301 리다이렉트
    # Google AdSense는 통일된 도메인(www)을 선호함
    if host == 'charliek.kr'
      # ads.txt도 리다이렉트하여 www.charliek.kr에서만 서빙되도록 통일
      redirect_url = "#{request.scheme}://#{CANONICAL_HOST}#{request.fullpath}"
      return [301, { 'Location' => redirect_url, 'Content-Type' => 'text/html' }, []]
    end
    
    # 다른 호스트는 그대로 진행 (Fly.io 서브도메인 등)
    @app.call(env)
  end
end
