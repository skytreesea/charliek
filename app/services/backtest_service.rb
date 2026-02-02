class BacktestService
  def initialize(params)
    @tickers = params[:tickers] || []
    @weights = params.fetch(:weights, {})
    @cash_weight = params[:cash_weight].to_f / 100.0
    # 날짜 형식을 강제로 고정
    @start_date = Date.parse(params[:start_date].to_s)
    @end_date = Date.parse(params[:end_date].to_s)
    @initial_capital = 1_000.0
    @exchange_rate = params[:exchange_rate].to_f > 0 ? params[:exchange_rate].to_f : 1350.0
  end

  def execute
    # 티커 정규화
    normalized_tickers = @tickers.map(&:upcase)
    
    # 1. 시작일의 주가를 정확히 '그 날짜' 혹은 '그 직전 영업일'로 한정 (과거 데이터 간섭 차단)
    # 모든 티커의 시작일 근처 데이터를 한 번에 조회 (N+1 방지)
    base_prices = {}
    
    # 모든 티커의 시작일 근처 데이터를 한 번에 조회 (대폭 최적화)
    extended_start_range = (@start_date - 30.days)..(@start_date + 7.days)
    start_date_records = DailyPrice.where("UPPER(ticker) IN (?)", normalized_tickers)
                                   .where(date: extended_start_range)
                                   .order(:ticker, :date)
                                   .to_a
                                   .group_by { |r| r.ticker.upcase }
    
    # 사용 가능한 티커 목록 캐시 (에러 메시지용, 한 번만 조회)
    available_tickers = nil
    
    # 각 티커별로 시작일에 가장 가까운 레코드 찾기 (메모리에서 처리)
    normalized_tickers.each do |normalized_ticker|
      records = start_date_records[normalized_ticker] || []
      
      before_records = records.select { |r| r.date <= @start_date }.sort_by(&:date).reverse
      after_records = records.select { |r| r.date >= @start_date }.sort_by(&:date)
      
      before_record = before_records.first
      after_record = after_records.first
      
      # 두 날짜 중 시작일에 더 가까운 것을 선택
      record = nil
      if before_record && after_record
        before_diff = (@start_date - before_record.date).to_i
        after_diff = (after_record.date - @start_date).to_i
        record = before_diff <= after_diff ? before_record : after_record
      elsif before_record
        record = before_record
      elsif after_record
        record = after_record
      end
      
      # 데이터가 없을 경우 상세한 디버깅 정보 제공
      unless record
        # 티커별 데이터 범위를 한 번에 조회 (에러 메시지용)
        ticker_stats = DailyPrice.where("UPPER(ticker) = ?", normalized_ticker)
                                .select("MIN(date) as min_date, MAX(date) as max_date, COUNT(*) as count")
                                .first
        
        if ticker_stats.nil? || ticker_stats.count.to_i == 0
          # 사용 가능한 티커 목록 조회 (한 번만, 캐시 활용)
          available_tickers ||= Rails.cache.fetch("available_tickers_list", expires_in: 1.hour) do
            DailyPrice.distinct.pluck(:ticker).sort
          end
          raise "시작일(#{@start_date}) 근처에 #{normalized_ticker}의 데이터가 없습니다. 데이터베이스에 #{normalized_ticker} 티커의 데이터가 전혀 없습니다. 사용 가능한 티커: #{available_tickers.join(', ')}. CSV를 다시 임포트하세요: rails daily_prices:import"
        else
          raise "시작일(#{@start_date}) 근처에 #{normalized_ticker}의 데이터가 없습니다. #{normalized_ticker}의 데이터 범위: #{ticker_stats.min_date} ~ #{ticker_stats.max_date}. 시작일을 이 범위 내로 조정하세요."
        end
      end
      
      original_ticker = @tickers.find { |t| t.upcase == normalized_ticker }
      base_prices[original_ticker] = record.close_price.to_f
    end

    # 2. 분석 기간 내의 모든 데이터를 한 번에 로드 (N+1 방지)
    # 날짜 범위를 넓게 잡아서 시작일 이전 데이터도 포함 (각 날짜별로 이전 가격 조회용)
    extended_start_date = @start_date - 30.days # 시작일 이전 30일까지 포함
    all_price_data = DailyPrice.where("UPPER(ticker) IN (?)", normalized_tickers)
                               .where("date >= ? AND date <= ?", extended_start_date, @end_date)
                               .order(:ticker, :date)
                               .to_a
    
    # 티커별, 날짜별로 인덱싱된 해시 생성 (빠른 조회용)
    price_index = {}
    all_price_data.each do |record|
      ticker_key = record.ticker.upcase
      price_index[ticker_key] ||= {}
      price_index[ticker_key][record.date] = record.close_price.to_f
    end
    
    # 분석 기간 내의 날짜 목록 추출
    dates = all_price_data.select { |r| r.date >= @start_date && r.date <= @end_date }
                          .map(&:date)
                          .uniq
                          .sort
    
    # 날짜가 없으면 에러 반환
    if dates.empty?
      return {
        error: "선택한 기간에 데이터가 없습니다. 다른 기간을 선택해주세요."
      }
    end
    
    daily_values = {}
    max_val = 0
    mdd = 0

    # 각 날짜별로 포트폴리오 가치 계산 (메모리에서 조회)
    dates.each do |date|
      # 현금 가치 (변하지 않음)
      current_portfolio_value = @initial_capital * @cash_weight

      # 주식 가치 합산 (메모리에서 조회)
      @tickers.each do |t|
        weight = @weights[t].to_f / 100.0
        normalized_t = t.upcase
        
        # 해당 날짜 이하의 가장 가까운 날짜의 주가를 메모리에서 찾기
        ticker_prices = price_index[normalized_t]
        next unless ticker_prices
        
        # 해당 날짜 이하의 가장 가까운 날짜 찾기
        available_dates = ticker_prices.keys.select { |d| d <= date }.sort.reverse
        next if available_dates.empty?
        
        closest_date = available_dates.first
        current_price = ticker_prices[closest_date]
        
        if base_prices[t] && base_prices[t] > 0 && current_price
          # 공식: 초기자본 * 비중 * (현재가 / 시작가)
          ratio = current_price / base_prices[t]
          current_portfolio_value += (@initial_capital * weight * ratio)
        end
      end

      val = current_portfolio_value.round(2)
      daily_values[date] = val

      # MDD 계산 (max_val이 0보다 큰 경우에만)
      if max_val > 0
        max_val = val if val > max_val
        drawdown = (max_val - val) / max_val
        mdd = drawdown if drawdown > mdd
      else
        max_val = val
      end
    end

    final_usd = daily_values.values.last || @initial_capital
    total_ret = @initial_capital > 0 ? ((final_usd - @initial_capital) / @initial_capital * 100).round(2) : 0.0

    {
      daily_values: daily_values,
      total_return: total_ret,
      final_value_usd: final_usd.round(2),
      final_value_krw: (final_usd * @exchange_rate).round(0),
      mdd: (mdd * 100).round(2)
    }
  end
end
