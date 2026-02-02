namespace :daily_prices do
  desc "Check DailyPrice setup and data status"
  task check: :environment do
    puts "\n🔍 DailyPrice 설정 및 데이터 상태 확인\n"
    puts "=" * 60
    
    # 1. 테이블 존재 여부 확인
    if DailyPrice.table_exists?
      puts "✅ DailyPrice 테이블 존재"
    else
      puts "❌ DailyPrice 테이블이 없습니다. 마이그레이션을 실행하세요: rails db:migrate"
      exit
    end
    
    # 2. 데이터 개수 확인
    total_count = DailyPrice.count
    puts "📊 전체 레코드 수: #{total_count}"
    
    if total_count > 0
      min_date = DailyPrice.minimum(:date)
      max_date = DailyPrice.maximum(:date)
      tickers = DailyPrice.distinct.pluck(:ticker).sort
      
      puts "📅 날짜 범위: #{min_date} ~ #{max_date}"
      puts "📈 티커 목록: #{tickers.join(', ')}"
      
      puts "\n티커별 데이터 개수:"
      tickers.each do |ticker|
        count = DailyPrice.where(ticker: ticker).count
        ticker_min = DailyPrice.where(ticker: ticker).minimum(:date)
        ticker_max = DailyPrice.where(ticker: ticker).maximum(:date)
        puts "  #{ticker}: #{count}개 (#{ticker_min} ~ #{ticker_max})"
      end
    else
      puts "⚠️  데이터가 없습니다."
    end
    
    # 3. CSV 파일 확인
    puts "\n📁 CSV 파일 확인:"
    CSV_DIR = Rails.root.join('public', 'data', 'yahoo_finance')
    puts "CSV 디렉토리: #{CSV_DIR}"
    
    if Dir.exist?(CSV_DIR)
      puts "✅ 디렉토리 존재"
      csv_files = Dir.glob(CSV_DIR.join("*.csv")).reject { |f| f.include?('Zone.Identifier') }
      if csv_files.any?
        puts "📄 CSV 파일 목록:"
        csv_files.each do |file|
          size = File.size(file)
          file_name = File.basename(file, '.csv')
          # 파일명에서 티커 추출
          ticker_match = file_name.match(/^([A-Za-z]+)/)
          ticker = ticker_match ? ticker_match[1].upcase : "알 수 없음"
          db_count = DailyPrice.where("UPPER(ticker) = ?", ticker).count if ticker != "알 수 없음"
          status = (ticker != "알 수 없음" && db_count && db_count > 0) ? "✅ (#{db_count}개)" : "⚠️"
          puts "  #{File.basename(file)} (#{size} bytes) → 티커: #{ticker} #{status}"
        end
      else
        puts "⚠️  CSV 파일이 없습니다."
      end
    else
      puts "❌ 디렉토리가 없습니다: #{CSV_DIR}"
      puts "   디렉토리를 생성하려면: mkdir -p #{CSV_DIR}"
    end
    
    # 4. 마이그레이션 상태 확인
    puts "\n🔄 마이그레이션 상태:"
    begin
      schema_version = ActiveRecord::Base.connection.execute("SELECT version FROM schema_migrations WHERE version = '20260118145230'").first
      if schema_version
        puts "✅ create_daily_prices 마이그레이션 실행됨"
      else
        puts "⚠️  create_daily_prices 마이그레이션이 실행되지 않았습니다."
        puts "   실행: rails db:migrate"
      end
    rescue => e
      puts "⚠️  마이그레이션 상태 확인 실패: #{e.message}"
    end
    
    puts "\n" + "=" * 60
    puts "\n다음 단계:"
    if total_count == 0
      puts "1. CSV 파일을 다운로드하여 #{CSV_DIR}에 저장"
      puts "2. rails daily_prices:import 실행"
    else
      puts "✅ 데이터가 준비되었습니다!"
    end
  end
end
