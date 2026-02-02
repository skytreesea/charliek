#!/usr/bin/env ruby
# Fly.io 서버에서 "음악" 카테고리를 "문화"로 변경하는 스크립트
# 사용법: fly ssh console -C "bash -c 'RAILS_ENV=production bin/rails runner /rails/fix_culture_category.rb'"

puts "=== 음악 -> 문화 카테고리 변경 ==="
puts ""

# 1. 현재 상태 확인
music_count = Post.where(category: "음악").count
culture_count = Post.where(category: "문화").count

puts "📊 현재 상태:"
puts "  - '음악' 카테고리: #{music_count}개"
puts "  - '문화' 카테고리: #{culture_count}개"
puts ""

if music_count == 0
  puts "✅ '음악' 카테고리 게시글이 없습니다. 변경할 것이 없습니다."
  exit
end

# 2. "음악"을 "문화"로 변경
puts "🔄 '음악' 카테고리를 '문화'로 변경 중..."
updated_count = Post.where(category: "음악").update_all(category: "문화")

puts "✅ 변경 완료: #{updated_count}개 게시글"
puts ""

# 3. 변경 후 확인
new_culture_count = Post.where(category: "문화").count
new_music_count = Post.where(category: "음악").count

puts "📊 변경 후 상태:"
puts "  - '문화' 카테고리: #{new_culture_count}개"
puts "  - '음악' 카테고리: #{new_music_count}개"
puts ""

# 4. 모든 카테고리 목록 확인
all_categories = Post.distinct.pluck(:category).compact.sort
puts "📋 모든 카테고리: #{all_categories.inspect}"
puts ""

puts "=== 완료 ==="
