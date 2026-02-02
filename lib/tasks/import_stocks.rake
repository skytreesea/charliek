require 'csv'

namespace :import_stocks do
  desc "구글 시트 날짜 형식을 지원하는 임포트 태스크"
  task run: :environment do
    path = Rails.root.join('public', 'data', 'stocks', '*.csv')
    files = Dir.glob(path)

    files.each do |file|
      ticker = File.basename(file, '.csv').upcase
      puts "🚀 Importing #{ticker}..."
      
      CSV.foreach(file, headers: true) do |row|
        next if row['Date'].blank? || row['Close'].blank?

        # 이미지 형식(2021. 1. 19) 대응 로직
        raw_date = row['Date'].to_s
        clean_date = raw_date.gsub('.', '-').gsub(' ', '').chomp('-')
        
        begin
          parsed_date = Date.parse(clean_date)
          
          DailyPrice.find_or_create_by!(ticker: ticker, date: parsed_date) do |dp|
            dp.close_price = row['Close'].to_s.gsub(',', '').to_f
          end
        rescue => e
          puts "❌ 파싱 에러 (#{ticker}): #{raw_date} - #{e.message}"
        end
      end
    end
    puts "✅ 임포트 완료! (DailyPrice.count: #{DailyPrice.count})"
  end
end
