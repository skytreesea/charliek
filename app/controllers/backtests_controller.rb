class BacktestsController < ApplicationController
  M7_TICKERS = %w[AAPL MSFT GOOGL AMZN META TSLA NVDA].freeze

  def index
    # 기본값 설정
    @selected_tickers = params[:tickers] || []
    @weights = params[:weights] || {}
    @cash_weight = params[:cash_weight]&.to_f || 0.0
    @exchange_rate = 1.0 # 달러 기준으로 고정
    
    # CSV 폴더에서 사용 가능한 티커 목록 동적 생성
    @available_tickers = available_tickers_from_csv
    
    # DailyPrice에 데이터가 있는 기간 조회 (단일 쿼리로 최적화)
    if DailyPrice.table_exists? && DailyPrice.exists?
      date_range = DailyPrice.select("MIN(date) as min_date, MAX(date) as max_date").first
      @min_date = date_range&.min_date || 5.years.ago.to_date
      @max_date = date_range&.max_date || Date.today
      # Date 객체로 확실히 변환
      @min_date = @min_date.is_a?(Date) ? @min_date : Date.parse(@min_date.to_s) if @min_date
      @max_date = @max_date.is_a?(Date) ? @max_date : Date.parse(@max_date.to_s) if @max_date
    else
      @min_date = 5.years.ago.to_date
      @max_date = Date.today
    end
    
    # 기본 시작일: 2025년 1월 2일
    default_start_date = Date.new(2025, 1, 2)
    # 데이터 범위 내에 있으면 사용, 아니면 데이터의 최소 날짜 사용
    if @min_date && default_start_date < @min_date
      default_start_date = @min_date
    elsif @max_date && default_start_date > @max_date
      default_start_date = @min_date || Date.today
    end
    
    @start_date = params[:start_date] || default_start_date.to_s
    @end_date = params[:end_date] || @max_date.to_s
    
    # 결과는 Turbo Stream으로 처리
    @result = nil
  end

  def calculate
    # 파라미터 파싱
    tickers = params[:tickers] || []
    weights = params[:weights] || {}
    cash_weight = params[:cash_weight]&.to_f || 0.0
    exchange_rate = 1.0 # 달러 기준으로 고정
    start_date = params[:start_date]
    end_date = params[:end_date]

    # 유효성 검증
    errors = validate_params(tickers, weights, cash_weight, start_date, end_date)
    
    if errors.any?
      render turbo_stream: turbo_stream.replace(
        "backtest_result",
        partial: "backtests/error",
        locals: { errors: errors }
      )
      return
    end

    # 백테스트 실행
    begin
      backtest_service = BacktestService.new(
        tickers: tickers,
        weights: weights,
        cash_weight: cash_weight,
        start_date: start_date,
        end_date: end_date,
        exchange_rate: exchange_rate
      )

      result = backtest_service.execute
      
      # 결과 형식 변환 (기존 뷰와 호환)
      if result[:daily_values]
        portfolio_values = result[:daily_values].map do |date, value|
          {
            date: date, # Date 객체 (뷰에서 사용)
            portfolio_value_usd: value,
            ticker_values: {}, # 개별 티커 가치는 계산하지 않음
            cash_value: (1_000.0 * cash_weight / 100.0).round(2)
          }
        end
        
        result = {
          total_return: result[:total_return],
          final_value_usd: result[:final_value_usd],
          max_drawdown: result[:mdd],
          initial_value: 1_000.0,
          final_value: result[:final_value_usd],
          portfolio_values: portfolio_values
        }
      end
    rescue => e
      render turbo_stream: turbo_stream.replace(
        "backtest_result",
        partial: "backtests/error",
        locals: { errors: [e.message] }
      )
      return
    end

    if result[:error]
      render turbo_stream: turbo_stream.replace(
        "backtest_result",
        partial: "backtests/error",
        locals: { errors: [result[:error]] }
      )
    else
      # 공유용 고유 ID 생성 및 결과 캐시 저장
      share_id = SecureRandom.uuid
      cache_key = "backtest_result_#{share_id}"
      
      # 공유용 데이터 준비 (티커 정보 포함)
      # 모든 객체를 직렬화 가능한 형태로 변환
      cacheable_result = {
        total_return: result[:total_return],
        final_value_usd: result[:final_value_usd],
        max_drawdown: result[:max_drawdown],
        initial_value: result[:initial_value],
        final_value: result[:final_value],
        portfolio_values: result[:portfolio_values].map do |pv|
          {
            date: pv[:date].to_s, # Date 객체를 문자열로 변환
            portfolio_value_usd: pv[:portfolio_value_usd].to_f,
            ticker_values: {}, # 빈 해시
            cash_value: pv[:cash_value].to_f
          }
        end
      }
      
      # ActionController::Parameters를 순수 해시/배열로 변환
      cacheable_tickers = tickers.is_a?(Array) ? tickers.map(&:to_s) : tickers.to_a.map(&:to_s)
      cacheable_weights = weights.is_a?(Hash) ? weights.to_h.transform_values(&:to_f) : weights.to_unsafe_h.transform_values(&:to_f)
      
      share_data = {
        result: cacheable_result,
        cash_weight: cash_weight.to_f,
        tickers: cacheable_tickers,
        weights: cacheable_weights,
        start_date: start_date.to_s,
        end_date: end_date.to_s
      }
      
      # 캐시에 7일간 저장
      Rails.cache.write(cache_key, share_data, expires_in: 7.days)
      
      render turbo_stream: turbo_stream.replace(
        "backtest_result",
        partial: "backtests/result",
        locals: { 
          result: result, 
          cash_weight: cash_weight,
          tickers: tickers,
          weights: weights,
          start_date: start_date,
          end_date: end_date,
          share_id: share_id
        }
      )
    end
  end

  def share
    share_id = params[:id]
    cache_key = "backtest_result_#{share_id}"
    share_data = Rails.cache.read(cache_key)
    
    if share_data.nil?
      flash[:alert] = "공유 링크가 만료되었거나 존재하지 않습니다."
      redirect_to backtests_path
      return
    end
    
    # 캐시에서 가져온 데이터를 뷰에서 사용할 수 있도록 변환
    # Date 문자열을 Date 객체로 변환
    cached_result = share_data[:result].dup
    if cached_result[:portfolio_values]
      cached_result[:portfolio_values] = cached_result[:portfolio_values].map do |pv|
        pv.dup.tap do |pv_hash|
          if pv_hash[:date].is_a?(String)
            begin
              pv_hash[:date] = Date.parse(pv_hash[:date])
            rescue ArgumentError => e
              Rails.logger.error "날짜 파싱 오류: #{pv_hash[:date]} - #{e.message}"
              # 기본값으로 오늘 날짜 사용
              pv_hash[:date] = Date.today
            end
          end
        end
      end
    end
    
    @result = cached_result
    @cash_weight = share_data[:cash_weight]
    @tickers = share_data[:tickers]
    @weights = share_data[:weights]
    @start_date = share_data[:start_date]
    @end_date = share_data[:end_date]
    @share_id = share_id
    @is_shared_page = true
    
    # SEO 메타 태그 설정
    ticker_names = @tickers.map { |t| Stock.display_name(t) }.join(', ')
    begin
      end_date_formatted = Date.parse(@end_date.to_s).strftime('%Y년 %m월 %d일')
      start_date_formatted = Date.parse(@start_date.to_s).strftime('%Y년 %m월 %d일')
    rescue ArgumentError => e
      Rails.logger.error "날짜 파싱 오류: #{e.message}"
      end_date_formatted = @end_date.to_s
      start_date_formatted = @start_date.to_s
    end
    return_percentage = @result[:total_return] >= 0 ? "+#{@result[:total_return]}" : @result[:total_return].to_s
    final_value_formatted = helpers.number_to_currency(@result[:final_value_usd], unit: "$", precision: 0, delimiter: ",")
    @page_title = "주식타임머신 결과: #{ticker_names} | CharlieK"
    @meta_description = "#{start_date_formatted}에 #{ticker_names}에 $1,000를 투자했다면, #{end_date_formatted}에는 #{final_value_formatted}(#{return_percentage}%)가 되었습니다."
    @og_title = @page_title
    @og_description = @meta_description
    @og_url = "#{request.base_url}#{request.path}"
    @og_image = "#{request.base_url}/icon.png"
    @og_type = "website"
    
    render :share
  end

  private

  # CSV 폴더에서 사용 가능한 티커 목록 추출 (캐싱 적용)
  def available_tickers_from_csv
    # 캐시 키 생성 (CSV 파일 변경 감지용)
    csv_dir = Rails.root.join('public', 'data', 'yahoo_finance')
    cache_key = if Dir.exist?(csv_dir)
      csv_files = Dir.glob(csv_dir.join("*.csv")).reject { |f| f.include?('Zone.Identifier') }
      file_mtimes = csv_files.map { |f| File.mtime(f).to_i }.sort
      "available_tickers_#{file_mtimes.join('_')}"
    else
      "available_tickers_default"
    end
    
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      unless Dir.exist?(csv_dir)
        next M7_TICKERS
      end
      
      # Zone.Identifier 파일 제외
      csv_files = Dir.glob(csv_dir.join("*.csv")).reject { |f| f.include?('Zone.Identifier') }
      tickers = Set.new
      
      csv_files.each do |file_path|
        file_name = File.basename(file_path, '.csv')
        # Zone.Identifier 파일 제외
        next if file_name.include?('Zone.Identifier')
        
        # 파일명에서 티커 추출: 여러 패턴 시도
        ticker = nil
        
        # 패턴 1: 파일명 전체에서 알파벳만 추출하여 티커 찾기
        all_letters = file_name.scan(/[A-Za-z]+/)
        known_tickers = %w[AAPL MSFT GOOGL AMZN META TSLA NVDA]
        all_letters.each do |letters|
          if known_tickers.any? { |kt| kt.upcase == letters.upcase }
            ticker = letters.upcase
            break
          end
        end
        
        # 패턴 2: 시작 부분의 알파벳만 추출
        if ticker.nil?
          ticker_match = file_name.match(/^([A-Za-z]{2,5})/)
          ticker = ticker_match[1].upcase if ticker_match
        end
        
        tickers.add(ticker) if ticker
      end
      
      # 데이터베이스에 실제로 데이터가 있는 티커만 반환 (단일 쿼리)
      if DailyPrice.table_exists? && DailyPrice.exists?
        db_tickers = DailyPrice.distinct.pluck(:ticker).map(&:upcase).to_set
        tickers = tickers.select { |t| db_tickers.include?(t) }
      end
      
      # 티커가 없으면 기본 M7 티커 반환
      tickers.empty? ? M7_TICKERS : tickers.sort
    end
  end

  def validate_params(tickers, weights, cash_weight, start_date, end_date)
    errors = []

    # 티커 검증
    if tickers.blank? || tickers.length == 0
      errors << "최소 1개 이상의 종목을 선택해주세요."
    elsif tickers.length > 3
      errors << "최대 3개까지만 선택할 수 있습니다."
    end

    # 비중 검증은 제거 (JavaScript에서 자동으로 100%로 맞춰짐)

    # 날짜 검증
    if start_date.blank? || end_date.blank?
      errors << "시작일과 종료일을 모두 선택해주세요."
    else
      begin
        parsed_start_date = Date.parse(start_date.to_s)
        parsed_end_date = Date.parse(end_date.to_s)
        
        if parsed_start_date > parsed_end_date
          errors << "시작일이 종료일보다 늦을 수 없습니다."
        end
      rescue ArgumentError => e
        errors << "날짜 형식이 올바르지 않습니다. YYYY-MM-DD 형식으로 입력해주세요."
      end
    end

    errors
  end
end
