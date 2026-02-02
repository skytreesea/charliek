class Stock
  # M7 종목 티커별 한글명과 설명
  STOCK_INFO = {
    'AAPL' => {
      name: '애플',
      description: '애플은 아이폰, 맥북, 아이패드 등 혁신적인 제품으로 전 세계 소비자 시장을 선도하는 기술 기업입니다. 하드웨어, 소프트웨어, 서비스를 통합한 생태계를 구축하여 높은 브랜드 충성도와 수익성을 유지하고 있습니다.'
    },
    'MSFT' => {
      name: '마이크로소프트',
      description: '마이크로소프트는 Windows 운영체제, Office 제품군, Azure 클라우드 서비스 등으로 기업과 개인 시장을 아우르는 글로벌 기술 기업입니다. 클라우드 전환과 AI 기술에 대한 투자로 지속적인 성장을 이어가고 있습니다.'
    },
    'GOOGL' => {
      name: '알파벳 (구글)',
      description: '알파벳은 구글 검색, YouTube, Android 등 핵심 플랫폼을 보유한 인터넷 거대 기업입니다. 디지털 광고 시장에서 강력한 지위를 유지하며, 클라우드 서비스와 AI 기술 개발에도 집중하고 있습니다.'
    },
    'AMZN' => {
      name: '아마존',
      description: '아마존은 전자상거래, 클라우드 컴퓨팅(AWS), 스트리밍 서비스 등 다양한 사업을 운영하는 글로벌 기술 기업입니다. 물류 네트워크와 기술 인프라를 바탕으로 지속적인 혁신과 확장을 추진하고 있습니다.'
    },
    'META' => {
      name: '메타 (페이스북)',
      description: '메타는 페이스북, Instagram, WhatsApp 등 소셜 미디어 플랫폼을 운영하며, 메타버스와 VR/AR 기술에 대한 장기 투자를 진행하고 있습니다. 디지털 광고 시장에서 강력한 영향력을 행사하고 있습니다.'
    },
    'TSLA' => {
      name: '테슬라',
      description: '테슬라는 전기차 시장을 선도하는 자동차 제조사이자 에너지 솔루션 기업입니다. 자율주행 기술과 에너지 저장 시스템에 대한 혁신적인 접근으로 지속 가능한 교통 수단의 미래를 만들어가고 있습니다.'
    },
    'NVDA' => {
      name: '엔비디아',
      description: '엔비디아는 GPU(그래픽 처리 장치) 시장에서 독보적인 위치를 차지하며, AI와 머신러닝, 데이터센터 시장에서 핵심 역할을 하고 있습니다. 최근 생성형 AI 붐으로 수요가 급증하며 급속한 성장을 보이고 있습니다.'
    }
  }.freeze

  # 시장 이벤트 (날짜와 이벤트명)
  # 실제 날짜는 연도별로 업데이트 필요
  MARKET_EVENTS = [
    { date: Date.new(2025, 1, 29), name: 'FOMC 금리 결정' },
    { date: Date.new(2025, 2, 21), name: 'NVDA 실적발표' },
    { date: Date.new(2025, 2, 11), name: 'CPI 발표' },
    { date: Date.new(2025, 3, 19), name: 'FOMC 금리 결정' },
    { date: Date.new(2025, 4, 23), name: 'NVDA 실적발표' },
    { date: Date.new(2025, 4, 10), name: 'CPI 발표' },
    { date: Date.new(2025, 5, 7), name: 'FOMC 금리 결정' },
    { date: Date.new(2025, 5, 21), name: 'NVDA 실적발표' },
    { date: Date.new(2025, 6, 11), name: 'CPI 발표' },
    { date: Date.new(2025, 6, 18), name: 'FOMC 금리 결정' }
  ].freeze

  # 티커 목록
  TICKERS = STOCK_INFO.keys.freeze

  # 티커로 한글명 조회
  def self.name(ticker)
    STOCK_INFO[ticker.upcase]&.dig(:name) || ticker
  end

  # 티커로 설명 조회
  def self.description(ticker)
    STOCK_INFO[ticker.upcase]&.dig(:description) || ''
  end

  # 티커로 "한글명 (Ticker)" 형식 반환
  def self.display_name(ticker)
    korean_name = name(ticker)
    korean_name == ticker ? ticker : "#{korean_name} (#{ticker})"
  end

  # 시장 이벤트 목록 반환 (드롭다운용)
  def self.market_events_for_select
    MARKET_EVENTS.map do |event|
      ["#{event[:name]} - #{event[:date].strftime('%Y-%m-%d')}", event[:date].to_s]
    end
  end

  # 특정 날짜 범위 내의 이벤트 조회
  def self.events_in_range(start_date, end_date)
    MARKET_EVENTS.select do |event|
      event[:date] >= start_date && event[:date] <= end_date
    end
  end
end
