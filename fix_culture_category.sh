#!/bin/bash
# Fly.io 서버에서 "음악" 카테고리를 "문화"로 변경하는 스크립트
# 사용법: 
#   1. fix_culture_category.rb 파일을 서버에 업로드
#   2. 이 스크립트 실행: ./fix_culture_category.sh

echo "Fly.io 서버에서 음악 -> 문화 카테고리 변경 중..."

# 방법 1: 스크립트 파일이 서버에 있는 경우
# fly ssh console -C "bash -c 'RAILS_ENV=production bin/rails runner /rails/fix_culture_category.rb'"

# 방법 2: 직접 명령어 실행 (스크립트 파일 없이)
fly ssh console -C "bash -c 'RAILS_ENV=production bin/rails runner \"music_count = Post.where(category: \\\"음악\\\").count; puts \\\"음악 카테고리: #{music_count}개\\\"; if music_count > 0; updated = Post.where(category: \\\"음악\\\").update_all(category: \\\"문화\\\"); puts \\\"변경 완료: #{updated}개\\\"; else; puts \\\"변경할 게시글이 없습니다.\\\"; end; puts \\\"문화 카테고리: #{Post.where(category: \\\"문화\\\").count}개\\\"\"'"
