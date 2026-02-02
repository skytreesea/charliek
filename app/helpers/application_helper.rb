module ApplicationHelper
  # Markdown → HTML. redcarpet 있으면 사용, 없으면 간단 변환(표준 라이브러리만)
  def markdown(text)
    return "" if text.blank?
    if defined?(::Redcarpet)
      renderer = ::Redcarpet::Render::HTML.new(filter_html: true, hard_wrap: true)
      md = ::Redcarpet::Markdown.new(renderer, fenced_code_blocks: true, autolink: true, tables: true)
      sanitize(md.render(text))
    else
      sanitize(simple_markdown(text))
    end
  end

  # redcarpet 없을 때: **굵게**, *기울임*, 링크, 줄바꿈만 처리
  def simple_markdown(text)
    s = text.to_s
    s = s.gsub(/\*\*(.+?)\*\*/, '<strong>\1</strong>')
    s = s.gsub(/\*(.+?)\*/, '<em>\1</em>')
    s = s.gsub(/\[([^\]]+)\]\(([^)]+)\)/, '<a href="\2" rel="noopener">\1</a>')
    s = s.gsub(/\r\n?/, "\n")
    s = s.split(/\n\n+/).map { |para| "<p>#{para.gsub(/\n/, '<br>')}</p>" }.join
    s.html_safe
  end

  # Pagy 페이지네이션 스타일 변경: <1> → [1]
  # 숫자만 포함된 < > 를 [ ] 로 변경 (HTML 태그는 제외)
  def pagy_nav_custom(pagy)
    return '' unless pagy
    nav_html = pagy.series_nav.to_s
    # <숫자> 형태를 [숫자]로 변경 (HTML 태그는 제외)
    nav_html.gsub(/<(\d+)>/, '[\1]').html_safe
  rescue
    # 에러 발생 시 원본 반환
    pagy.series_nav.html_safe
  end

  # 숫자를 K/M 형식으로 포맷팅 (1000 -> 1K, 1000000 -> 1M)
  def format_number_short(number)
    return '0' if number.nil? || number == 0
    
    number = number.to_i
    
    if number >= 1_000_000
      "#{(number / 1_000_000.0).round(1)}M".gsub(/\.0/, '')
    elsif number >= 1_000
      "#{(number / 1_000.0).round(1)}K".gsub(/\.0/, '')
    else
      number.to_s
    end
  end

  # 게시글 내용의 이미지 태그에 alt 속성 자동 추가 (SEO 최적화)
  def add_alt_to_images(content, default_alt = "이미지")
    return content if content.blank?
    
    # 이미지 태그를 찾아서 alt 속성이 없으면 추가
    content.gsub(/<img([^>]*?)>/i) do |img_tag|
      # alt 속성이 이미 있는지 확인
      if img_tag =~ /alt\s*=\s*["']([^"']*)["']/i
        img_tag # alt 속성이 있으면 그대로 반환
      else
        # alt 속성이 없으면 추가
        img_tag.gsub(/<img([^>]*?)(\s*\/?)>/i, "<img\\1 alt=\"#{default_alt}\"\\2>")
      end
    end
  end

  # 티커를 "한글명 (Ticker)" 형식으로 반환
  def stock_display_name(ticker)
    Stock.display_name(ticker)
  end

  # 시장 이벤트를 드롭다운용 옵션으로 반환
  def market_events_options
    Stock.market_events_for_select
  end

  # 코드 이름을 기타 음표 배열로 변환 (Tone.js Sampler용)
  def chord_to_notes(chord_name)
    # 기타 코드 구성음 (6줄 기타 기준, 낮은 음에서 높은 음 순서)
    chord_notes = {
      'C' => ['C3', 'E3', 'G3', 'C4', 'E4'],
      'Dm' => ['D3', 'A3', 'D4', 'F4'],
      'Em' => ['E2', 'B2', 'E3', 'G3', 'B3', 'E4'],
      'F' => ['F2', 'A2', 'C3', 'F3', 'A3', 'C4'],
      'G' => ['G2', 'B2', 'D3', 'G3', 'B3', 'G4'],
      'Am' => ['A2', 'E3', 'A3', 'C4', 'E4'],
      'Em7' => ['E2', 'B2', 'D3', 'E3', 'G3', 'B3'],
      'Fmaj7' => ['F2', 'A2', 'C3', 'E3', 'F3', 'A3'],
      'E' => ['E2', 'B2', 'E3', 'G#3', 'B3', 'E4']
    }
    
    chord_notes[chord_name] || ['C3', 'E3', 'G3']
  end
end
