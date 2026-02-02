namespace :timezone do
  desc "기존 UTC 시간 데이터를 한국 시간대로 변환 (실제로는 표시만 변경되므로 이 태스크는 선택사항)"
  task convert_to_kst: :environment do
    puts "⚠️  주의: Rails는 데이터베이스에 UTC로 저장하고 표시 시 타임존을 적용합니다."
    puts "⚠️  따라서 데이터베이스의 값 자체를 변경할 필요는 없습니다."
    puts "⚠️  config.time_zone = 'Seoul' 설정만으로 모든 시간이 한국 시간으로 표시됩니다."
    puts ""
    puts "현재 타임존 설정: #{Time.zone.name}"
    puts "현재 시간: #{Time.zone.now}"
    puts ""
    puts "다음 명령어로 각 모델의 시간을 확인할 수 있습니다:"
    puts "  rails console"
    puts "  Post.first.created_at"
    puts "  Guestbook.first.created_at"
    puts ""
    puts "모든 시간이 한국 시간(KST)으로 표시됩니다."
  end

  desc "기존 데이터의 시간 정보 확인"
  task check_times: :environment do
    puts "=== 시간 정보 확인 ==="
    puts "현재 타임존: #{Time.zone.name}"
    puts "현재 시간: #{Time.zone.now}"
    puts ""
    
    if Post.any?
      puts "게시글 예시:"
      post = Post.first
      puts "  ID: #{post.id}"
      puts "  제목: #{post.title}"
      puts "  작성 시간 (DB): #{post.created_at}"
      puts "  작성 시간 (KST): #{post.created_at.in_time_zone('Seoul')}"
      puts ""
    end
    
    if Guestbook.any?
      puts "방명록 예시:"
      guestbook = Guestbook.first
      puts "  ID: #{guestbook.id}"
      puts "  작성 시간 (DB): #{guestbook.created_at}"
      puts "  작성 시간 (KST): #{guestbook.created_at.in_time_zone('Seoul')}"
      puts ""
    end
    
    if Comment.any?
      puts "댓글 예시:"
      comment = Comment.first
      puts "  ID: #{comment.id}"
      puts "  작성 시간 (DB): #{comment.created_at}"
      puts "  작성 시간 (KST): #{comment.created_at.in_time_zone('Seoul')}"
    end
  end
end
