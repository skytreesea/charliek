class Admin::DesignController < ApplicationController
  before_action :authenticate_user!
  before_action :check_super_admin

  def index
    @design_settings = load_design_settings
    @available_fonts = [
      { name: 'Noto Sans KR', value: "'Noto Sans KR', sans-serif", url: 'https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;500;600;700&display=swap' },
      { name: 'Nanum Gothic', value: "'Nanum Gothic', sans-serif", url: 'https://fonts.googleapis.com/css2?family=Nanum+Gothic:wght@400;700;800&display=swap' },
      { name: 'Nanum Myeongjo', value: "'Nanum Myeongjo', serif", url: 'https://fonts.googleapis.com/css2?family=Nanum+Myeongjo:wght@400;700;800&display=swap' },
      { name: 'Do Hyeon', value: "'Do Hyeon', sans-serif", url: 'https://fonts.googleapis.com/css2?family=Do+Hyeon&display=swap' },
      { name: 'Jua', value: "'Jua', sans-serif", url: 'https://fonts.googleapis.com/css2?family=Jua&display=swap' }
    ]
  end

  def update
    design_params = params[:design] || {}
    
    # 색상 설정 저장
    %w[bg card primary text].each do |key|
      color_key = "theme_#{key}"
      if design_params[color_key].present?
        Setting.set(color_key, design_params[color_key])
      end
    end
    
    # 테두리와 호버 색상은 투명도 적용
    if design_params[:theme_border].present?
      border_color = design_params[:theme_border]
      # HEX를 RGBA로 변환 (투명도 20%)
      if border_color.start_with?('#') && border_color.length == 7
        r = border_color[1..2].to_i(16)
        g = border_color[3..4].to_i(16)
        b = border_color[5..6].to_i(16)
        Setting.set('theme_border', "rgba(#{r}, #{g}, #{b}, 0.2)")
      else
        Setting.set('theme_border', border_color)
      end
    end
    
    if design_params[:theme_hover].present?
      hover_color = design_params[:theme_hover]
      # HEX를 RGBA로 변환 (투명도 15%)
      if hover_color.start_with?('#') && hover_color.length == 7
        r = hover_color[1..2].to_i(16)
        g = hover_color[3..4].to_i(16)
        b = hover_color[5..6].to_i(16)
        Setting.set('theme_hover', "rgba(#{r}, #{g}, #{b}, 0.15)")
      else
        Setting.set('theme_hover', hover_color)
      end
    end
    
    # 폰트 설정 저장
    %w[heading body button link nav code footer].each do |key|
      font_key = "font_#{key}"
      if design_params[font_key].present?
        Setting.set(font_key, design_params[font_key])
      end
    end
    
    redirect_to "/admin/design", notice: "디자인 설정이 업데이트되었습니다."
  end

  private

  def check_super_admin
    unless current_user&.super_admin?
      redirect_to "/", alert: "수퍼관리자만 접근할 수 있습니다.", status: :forbidden
    end
  end

  def load_design_settings
    {
      theme_bg: Setting.get('theme_bg', '#FAF9F6'),
      theme_card: Setting.get('theme_card', '#FFFFFF'),
      theme_primary: Setting.get('theme_primary', '#D4A373'),
      theme_text: Setting.get('theme_text', '#433E3F'),
      theme_border: Setting.get('theme_border', 'rgba(212, 163, 115, 0.2)'),
      theme_hover: Setting.get('theme_hover', 'rgba(212, 163, 115, 0.15)'),
      font_heading: Setting.get('font_heading', 'system-ui, sans-serif'),
      font_body: Setting.get('font_body', 'system-ui, sans-serif'),
      font_button: Setting.get('font_button', 'system-ui, sans-serif'),
      font_link: Setting.get('font_link', 'system-ui, sans-serif'),
      font_nav: Setting.get('font_nav', 'system-ui, sans-serif'),
      font_code: Setting.get('font_code', "'Courier New', monospace"),
      font_footer: Setting.get('font_footer', 'system-ui, sans-serif')
    }
  end
end
