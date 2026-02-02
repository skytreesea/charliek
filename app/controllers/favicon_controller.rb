class FaviconController < ActionController::Base
  # Edge 브라우저 호환성을 위한 favicon.ico 서빙
  # ApplicationController를 상속받지 않아 before_action들을 우회
  def show
    # icon.png 파일을 직접 서빙
    icon_path = Rails.root.join('public', 'icon.png')
    
    if File.exist?(icon_path)
      send_file icon_path, 
        type: 'image/x-icon', 
        disposition: 'inline',
        cache_control: 'public, max-age=31536000'
    else
      head :not_found
    end
  end
end
