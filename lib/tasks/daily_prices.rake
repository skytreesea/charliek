namespace :daily_prices do
  desc "Import daily prices from Yahoo Finance CSV files"
  task import: :environment do
    # CSV 파일 경로 (public/data/ 또는 lib/data/ 폴더에 저장)
    CSV_DIR = Rails.root.join('public', 'data', 'yahoo_finance')
    
    puts "Starting daily prices import..."
    puts "CSV directory: #{CSV_DIR}"
    
    # 디렉토리가 없으면 생성
    FileUtils.mkdir_p(CSV_DIR) unless Dir.exist?(CSV_DIR)
    
    # CSV 파일에서 티커 자동 추출 (Zone.Identifier 파일 제외)
    csv_files = Dir.glob(CSV_DIR.join("*.csv")).reject { |f| f.include?('Zone.Identifier') }
    
    if csv_files.empty?
      puts "⚠️  CSV 파일이 없습니다. #{CSV_DIR} 폴더에 CSV 파일을 추가하세요."
      return
    end
    
    # 파일명에서 티커 추출 (대소문자 구분 없음)
    ticker_files = {}
    csv_files.each do |file_path|
      file_name = File.basename(file_path, '.csv')
      # Zone.Identifier 파일 제외
      next if file_name.include?('Zone.Identifier')
      
      # 파일명에서 티커 추출: 여러 패턴 시도
      ticker = nil
      
      # 패턴 1: 파일명 전체에서 알파벳만 추출하여 티커 찾기 (2-5글자)
      # 예: "m7 - amzn" → "amzn", "msft - 시트1" → "msft", "AAPL" → "AAPL"
      all_letters = file_name.scan(/[A-Za-z]+/)
      # 알려진 티커 목록과 매칭 (대소문자 구분 없음)
      known_tickers = %w[AAPL MSFT GOOGL AMZN META TSLA NVDA]
      all_letters.each do |letters|
        if known_tickers.any? { |kt| kt.upcase == letters.upcase }
          ticker = letters.upcase
          break
        end
      end
      
      # 패턴 2: 시작 부분의 알파벳만 추출 (패턴 1이 실패한 경우)
      if ticker.nil?
        ticker_match = file_name.match(/^([A-Za-z]{2,5})/)
        ticker = ticker_match[1].upcase if ticker_match
      end
      
      if ticker
        ticker_files[ticker] ||= []
        ticker_files[ticker] << file_path
        puts "   파일: #{File.basename(file_path)} → 티커: #{ticker}"
      else
        puts "   ⚠️  티커를 추출할 수 없음: #{File.basename(file_path)}"
      end
    end
    
    if ticker_files.empty?
      puts "⚠️  CSV 파일에서 티커를 추출할 수 없습니다."
      return
    end
    
    puts "발견된 티커: #{ticker_files.keys.sort.join(', ')}"
    
    ticker_files.each do |ticker, files|
      # 같은 티커의 파일이 여러 개 있으면 첫 번째 것 사용
      csv_file = files.first
      
      puts "\n📊 Processing #{ticker} from #{File.basename(csv_file)}..."
      
      begin
        require 'csv'
        
        imported_count = 0
        skipped_count = 0
        error_count = 0
        
        # CSV 파일의 첫 몇 줄 확인 (디버깅용)
        first_lines = File.readlines(csv_file).first(3)
        puts "   CSV 파일 첫 3줄:"
        first_lines.each { |line| puts "     #{line.chomp}" }
        
        # CSV 파일 인코딩 확인 및 처리
        csv_content = File.read(csv_file)
        # BOM 제거 (UTF-8 BOM이 있을 경우)
        csv_content = csv_content.force_encoding('UTF-8').sub("\xEF\xBB\xBF", '')
        
        CSV.parse(csv_content, headers: true) do |row|
          begin
            # Yahoo Finance CSV 형식: Date,Open,High,Low,Close,Adj Close,Volume
            # Adj Close(수정종가)를 우선 사용, 없으면 Close 사용
            # 헤더가 대소문자 구분 없이 작동하도록
            date_str = row['Date'] || row['date'] || row['DATE'] || row[0]
            
            # CSV 헤더 검증: Close 또는 Adj Close 컬럼을 명확히 찾기
            # Volume 컬럼을 주가로 오인하지 않도록 주의
            close_price_str = nil
            
            # Adj Close 우선 검색 (명시적 컬럼명만)
            if row.headers.include?('Adj Close') || row.headers.include?('adj close') || row.headers.include?('ADJ CLOSE')
              close_price_str = row['Adj Close'] || row['adj close'] || row['ADJ CLOSE']
            end
            
            # Adj Close가 없으면 Close 검색
            if close_price_str.nil? || close_price_str.to_s.strip.empty?
              if row.headers.include?('Close') || row.headers.include?('close') || row.headers.include?('CLOSE')
                close_price_str = row['Close'] || row['close'] || row['CLOSE']
              end
            end
            
            # 헤더로 찾지 못한 경우에만 인덱스 사용 (하지만 경고 출력)
            if (close_price_str.nil? || close_price_str.to_s.strip.empty?)
              # CSV 형식에 따라 인덱스 사용
              # 형식 1: Date,Open,High,Low,Close,Adj Close,Volume (7개 컬럼)
              # 형식 2: Date,Open,High,Low,Close,Volume (6개 컬럼)
              if row.headers.length >= 7
                # Adj Close가 5번 인덱스, Close가 4번 인덱스
                if row[5] && row[5].to_s.strip.match?(/^\d+\.?\d*$/)
                  close_price_str = row[5]
                elsif row[4] && row[4].to_s.strip.match?(/^\d+\.?\d*$/)
                  close_price_str = row[4]
                end
              elsif row.headers.length >= 6
                # Close가 4번 인덱스
                if row[4] && row[4].to_s.strip.match?(/^\d+\.?\d*$/)
                  close_price_str = row[4]
                end
              end
            end
            
            # 디버깅: 첫 번째 행 출력
            if imported_count == 0 && skipped_count == 0 && error_count == 0
              puts "   첫 번째 행 샘플: Date=#{date_str}, Close=#{close_price_str}"
              puts "   CSV 헤더: #{row.headers.inspect}"
              puts "   티커: #{ticker}"
            end
            
            next if date_str.nil? || close_price_str.nil? || date_str.strip.empty? || close_price_str.strip.empty?
            
            # 날짜 파싱 (다양한 형식 지원)
            begin
              date_str_clean = date_str.strip
              
              # 한국어 날짜 형식 처리: "2021. 1. 19 오후 4:00:00" -> "2021-01-19"
              if date_str_clean.match?(/\d{4}\.\s*\d{1,2}\.\s*\d{1,2}/)
                # "2021. 1. 19 오후 4:00:00" 형식에서 날짜 부분만 추출
                # 정규식으로 년.월.일 부분만 추출
                match = date_str_clean.match(/(\d{4})\.\s*(\d{1,2})\.\s*(\d{1,2})/)
                if match
                  year = match[1]
                  month = match[2].rjust(2, '0')
                  day = match[3].rjust(2, '0')
                  date_str_clean = "#{year}-#{month}-#{day}"
                else
                  # 정규식 매칭 실패 시 기본 파싱 시도
                  date_str_clean = date_str_clean.gsub(/\./, '-').gsub(/\s+/, ' ').split(' ').first
                end
              end
              
              date = Date.parse(date_str_clean)
            rescue => e
              puts "   날짜 파싱 오류: #{date_str} -> #{date_str_clean rescue date_str} - #{e.message}"
              next
            end
            
            # 날짜 범위 제한 제거 (모든 데이터 처리)
            # five_years_ago = Date.today - 5.years
            # next if date < five_years_ago
            
            # 종가 파싱
            close_price = close_price_str.to_f
            
            next if close_price <= 0
            
            # 데이터 저장 (중복 체크)
            daily_price = DailyPrice.find_or_initialize_by(ticker: ticker, date: date)
            
            if daily_price.new_record?
              daily_price.close_price = close_price
              if daily_price.save
                imported_count += 1
                # 진행 상황 표시 (1000개마다)
                if imported_count % 1000 == 0
                  puts "   ... #{imported_count}개 임포트됨"
                end
              else
                error_count += 1
                puts "   ❌ Error saving #{date}: #{daily_price.errors.full_messages.join(', ')}"
                # 처음 10개 오류만 상세 출력
                if error_count <= 10
                  puts "     데이터: ticker=#{ticker}, date=#{date}, close_price=#{close_price}"
                end
              end
            else
              # 기존 데이터가 있으면 가격 업데이트
              if daily_price.close_price != close_price
                daily_price.update(close_price: close_price)
                imported_count += 1
              else
                skipped_count += 1
              end
            end
            
          rescue => e
            error_count += 1
            puts "   Error processing row: #{e.message}"
            next
          end
        end
        
        puts "   ✅ Imported: #{imported_count}, Skipped: #{skipped_count}, Errors: #{error_count}"
        
        # 임포트 후 데이터베이스 확인
        db_count = DailyPrice.where("UPPER(ticker) = ?", ticker).count
        if db_count > 0
          min_date = DailyPrice.where("UPPER(ticker) = ?", ticker).minimum(:date)
          max_date = DailyPrice.where("UPPER(ticker) = ?", ticker).maximum(:date)
          puts "   📊 데이터베이스 확인: #{db_count}개 레코드 (#{min_date} ~ #{max_date})"
        else
          puts "   ⚠️  경고: 데이터베이스에 #{ticker} 데이터가 없습니다!"
        end
        
      rescue => e
        puts "   ❌ Failed to process #{ticker}: #{e.message}"
        puts "   #{e.backtrace.first(3).join("\n   ")}"
      end
    end
    
    puts "\n✨ Import completed!"
    
    # 최종 통계
    puts "\n📊 최종 데이터베이스 통계:"
    if DailyPrice.table_exists? && DailyPrice.exists?
      tickers_in_db = DailyPrice.distinct.pluck(:ticker).map(&:upcase).uniq.sort
      puts "   데이터베이스에 있는 티커: #{tickers_in_db.join(', ')}"
      tickers_in_db.each do |t|
        count = DailyPrice.where("UPPER(ticker) = ?", t).count
        puts "   - #{t}: #{count}개"
      end
    end
    puts "\nTo download CSV files from Yahoo Finance:"
    puts "1. Go to https://finance.yahoo.com/quote/AAPL/history"
    puts "2. Select '5Y' time period"
    puts "3. Click 'Download' button"
    puts "4. Save the file as: #{CSV_DIR}/AAPL.csv"
    puts "5. Repeat for each ticker (MSFT, GOOGL, AMZN, META, TSLA, NVDA)"
  end
  
  desc "Show statistics for imported daily prices"
  task stats: :environment do
    puts "\n📈 Daily Prices Statistics\n"
    puts "=" * 60
    
    if DailyPrice.table_exists? && DailyPrice.exists?
      # 데이터베이스에 있는 모든 티커 가져오기
      tickers = DailyPrice.distinct.pluck(:ticker).map(&:upcase).uniq.sort
      
      if tickers.empty?
        puts "⚠️  데이터베이스에 데이터가 없습니다."
      else
        tickers.each do |ticker|
          count = DailyPrice.where("UPPER(ticker) = ?", ticker).count
          if count > 0
            oldest = DailyPrice.where("UPPER(ticker) = ?", ticker).minimum(:date)
            newest = DailyPrice.where("UPPER(ticker) = ?", ticker).maximum(:date)
            latest_price = DailyPrice.where("UPPER(ticker) = ?", ticker).order(date: :desc).first&.close_price
            
            puts "#{ticker.ljust(6)} | Records: #{count.to_s.rjust(5)} | Date Range: #{oldest} ~ #{newest} | Latest: $#{latest_price&.round(2)}"
          else
            puts "#{ticker.ljust(6)} | No data"
          end
        end
      end
    else
      puts "⚠️  DailyPrice 테이블이 없거나 데이터가 없습니다."
    end
    
    puts "=" * 60
    puts "Total records: #{DailyPrice.count}"
  end
  
  desc "Clear all daily prices data"
  task clear: :environment do
    print "Are you sure you want to delete all daily prices? (yes/no): "
    confirmation = STDIN.gets.chomp
    
    if confirmation.downcase == 'yes'
      count = DailyPrice.count
      DailyPrice.delete_all
      puts "✅ Deleted #{count} records"
    else
      puts "❌ Cancelled"
    end
  end
  
  desc "Check if specific ticker and date exists in database"
  task :check_ticker, [:ticker, :date] => :environment do |t, args|
    ticker = args[:ticker] || 'AAPL'
    date_str = args[:date] || Date.today.to_s
    
    begin
      check_date = Date.parse(date_str)
    rescue => e
      puts "❌ 날짜 파싱 오류: #{date_str} - #{e.message}"
      exit
    end
    
    puts "\n🔍 티커 및 날짜 확인"
    puts "=" * 60
    puts "티커: #{ticker}"
    puts "확인 날짜: #{check_date}"
    puts "=" * 60
    
    # 전체 데이터 확인
    total_count = DailyPrice.where(ticker: ticker).count
    puts "\n📊 #{ticker} 전체 데이터: #{total_count}개"
    
    if total_count == 0
      puts "❌ #{ticker} 티커의 데이터가 없습니다."
      available_tickers = DailyPrice.distinct.pluck(:ticker).sort
      if available_tickers.any?
        puts "\n사용 가능한 티커: #{available_tickers.join(', ')}"
      else
        puts "\n⚠️  데이터베이스에 데이터가 전혀 없습니다."
        puts "   CSV를 임포트하세요: rails daily_prices:import"
      end
      exit
    end
    
    # 날짜 범위 확인
    min_date = DailyPrice.where(ticker: ticker).minimum(:date)
    max_date = DailyPrice.where(ticker: ticker).maximum(:date)
    puts "📅 날짜 범위: #{min_date} ~ #{max_date}"
    
    # 정확한 날짜 확인
    exact_record = DailyPrice.where(ticker: ticker, date: check_date).first
    if exact_record
      puts "✅ 정확한 날짜 데이터 발견: #{check_date} - $#{exact_record.close_price}"
    else
      puts "⚠️  정확한 날짜 데이터 없음: #{check_date}"
    end
    
    # 근처 날짜 확인
    before_record = DailyPrice.where(ticker: ticker)
                             .where("date <= ?", check_date)
                             .order(date: :desc)
                             .first
    
    after_record = DailyPrice.where(ticker: ticker)
                            .where("date >= ?", check_date)
                            .order(date: :asc)
                            .first
    
    puts "\n근처 날짜 확인:"
    if before_record
      diff = (check_date - before_record.date).to_i
      puts "  이전 날짜: #{before_record.date} (#{diff}일 전) - $#{before_record.close_price}"
    else
      puts "  이전 날짜: 없음"
    end
    
    if after_record
      diff = (after_record.date - check_date).to_i
      puts "  이후 날짜: #{after_record.date} (#{diff}일 후) - $#{after_record.close_price}"
    else
      puts "  이후 날짜: 없음"
    end
    
    # 최종 추천
    if before_record || after_record
      recommended_date = if before_record && after_record
        before_diff = (check_date - before_record.date).to_i
        after_diff = (after_record.date - check_date).to_i
        before_diff <= after_diff ? before_record.date : after_record.date
      elsif before_record
        before_record.date
      else
        after_record.date
      end
      puts "\n💡 추천 시작일: #{recommended_date}"
    else
      puts "\n❌ #{check_date} 근처에 데이터가 없습니다."
    end
    
    puts "\n" + "=" * 60
  end
end
