#!/usr/bin/env ruby
# Fly.io 서버에서 "문화" 카테고리 게시글 확인 스크립트
# 사용법: fly ssh console -C "RAILS_ENV=production bin/rails runner /rails/check_culture_posts.rb"

puts "=== 문화 카테고리 확인 ==="
puts ""

# 1. 모든 카테고리 목록
all_categories = Post.distinct.pluck(:category).compact.sort
puts "📋 모든 카테고리: #{all_categories.inspect}"
puts ""

# 2. 정확한 매칭으로 "문화" 카테고리 게시글 수
culture_posts_exact = Post.where(category: "문화")
culture_count_exact = culture_posts_exact.count
puts "✅ 정확한 매칭 (category = '문화'): #{culture_count_exact}개"
puts ""

# 3. TRIM으로 찾은 "문화" 카테고리 게시글 수
begin
  culture_posts_trim = Post.where("TRIM(category) = ?", "문화")
  culture_count_trim = culture_posts_trim.count
  puts "✅ TRIM 매칭 (TRIM(category) = '문화'): #{culture_count_trim}개"
rescue => e
  puts "❌ TRIM 쿼리 실패: #{e.message}"
end
puts ""

# 4. "문화" 게시글 상세 정보
if culture_count_exact > 0
  puts "📝 문화 카테고리 게시글 목록:"
  culture_posts_exact.each do |post|
    puts "  - ID: #{post.id}, 제목: #{post.title}, 카테고리: #{post.category.inspect}"
    puts "    카테고리 bytes: #{post.category.bytes.inspect}" if post.category
  end
else
  puts "⚠️  정확한 매칭으로 찾은 '문화' 카테고리 게시글이 없습니다."
end
puts ""

# 5. Ruby 레벨에서 정규화 후 비교
normalized_target = "문화".unicode_normalize(:nfc).strip
all_posts = Post.all.to_a
matched_posts = all_posts.select do |p|
  next false unless p.category
  cat = p.category.to_s.unicode_normalize(:nfc).strip
  cat == normalized_target
end

puts "🔍 Ruby 레벨 정규화 후 매칭: #{matched_posts.size}개"
if matched_posts.size > 0
  puts "📝 매칭된 게시글:"
  matched_posts.each do |post|
    puts "  - ID: #{post.id}, 제목: #{post.title}, 원본 카테고리: #{post.category.inspect}"
  end
end
puts ""

# 6. 카테고리별 통계
puts "📊 카테고리별 게시글 수:"
Post::CATEGORIES.each do |cat|
  count = Post.where(category: cat).count
  puts "  - #{cat}: #{count}개"
end
puts ""

puts "=== 확인 완료 ==="
