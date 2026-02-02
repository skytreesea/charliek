namespace :posts do
  desc "Fix posts with NULL or invalid categories"
  task fix_categories: :environment do
    puts "🔧 게시글 카테고리 수정 시작..."
    
    # NULL 카테고리를 가진 게시글 수
    null_count = Post.where(category: nil).count
    puts "  NULL 카테고리 게시글: #{null_count}개"
    
    # 빈 문자열 카테고리를 가진 게시글 수
    empty_count = Post.where(category: "").count
    puts "  빈 문자열 카테고리 게시글: #{empty_count}개"
    
    # 유효하지 않은 카테고리를 가진 게시글 수
    invalid_posts = Post.where.not(category: Post::CATEGORIES).where.not(category: nil).where.not(category: "")
    invalid_count = invalid_posts.count
    puts "  유효하지 않은 카테고리 게시글: #{invalid_count}개"
    
    # 데이터베이스에 있는 모든 카테고리 값 확인
    all_categories = Post.distinct.pluck(:category).compact.reject(&:blank?)
    puts "  데이터베이스의 모든 카테고리 값: #{all_categories.inspect}"
    
    # NULL 또는 빈 문자열 카테고리를 기본값("주식")으로 설정
    fixed_null = Post.where(category: nil).update_all(category: "주식")
    fixed_empty = Post.where(category: "").update_all(category: "주식")
    
    puts "  ✅ NULL 카테고리 수정: #{fixed_null}개"
    puts "  ✅ 빈 문자열 카테고리 수정: #{fixed_empty}개"
    
    # "주식/경제" 같은 이전 카테고리를 "주식"으로 변경
    old_category_patterns = ["주식/경제", "주식/경제 ", " 주식/경제"]
    old_category_patterns.each do |old_pattern|
      fixed_old = Post.where(category: old_pattern).update_all(category: "주식")
      puts "  ✅ '#{old_pattern}' 카테고리 수정: #{fixed_old}개" if fixed_old > 0
    end
    
    # 유효하지 않은 카테고리를 기본값으로 설정 (자동으로 변경)
    if invalid_count > 0
      puts "\n  ⚠️  유효하지 않은 카테고리 게시글 목록:"
      invalid_posts.limit(10).each do |post|
        puts "    ID: #{post.id}, 제목: #{post.title}, 현재 카테고리: #{post.category.inspect}"
      end
      
      # 자동으로 "주식"으로 변경 (프로덕션에서는 자동 실행)
      fixed_invalid = invalid_posts.update_all(category: "주식")
      puts "  ✅ 유효하지 않은 카테고리 수정: #{fixed_invalid}개"
    end
    
    # 최종 통계
    puts "\n📊 최종 통계:"
    Post::CATEGORIES.each do |category|
      count = Post.where(category: category).count
      puts "  #{category}: #{count}개"
    end
    null_final = Post.where(category: nil).count
    puts "  NULL: #{null_final}개"
    
    puts "\n✨ 카테고리 수정 완료!"
  end
  
  desc "Show posts category statistics"
  task stats: :environment do
    puts "\n📊 게시글 카테고리 통계\n"
    puts "=" * 60
    
    total = Post.count
    puts "전체 게시글: #{total}개\n"
    
    Post::CATEGORIES.each do |category|
      count = Post.where(category: category).count
      percentage = total > 0 ? (count.to_f / total * 100).round(2) : 0
      puts "#{category.ljust(10)}: #{count.to_s.rjust(5)}개 (#{percentage}%)"
    end
    
    null_count = Post.where(category: nil).count
    empty_count = Post.where(category: "").count
    invalid_posts = Post.where.not(category: Post::CATEGORIES).where.not(category: nil).where.not(category: "")
    invalid_count = invalid_posts.count
    
    puts "\n문제가 있는 게시글:"
    puts "  NULL 카테고리: #{null_count}개"
    puts "  빈 문자열 카테고리: #{empty_count}개"
    puts "  유효하지 않은 카테고리: #{invalid_count}개"
    
    if invalid_count > 0
      puts "\n유효하지 않은 카테고리 목록:"
      invalid_posts.limit(20).each do |post|
        puts "  ID: #{post.id}, 카테고리: #{post.category.inspect}, 제목: #{post.title}"
      end
    end
    
    puts "\n" + "=" * 60
  end
end
