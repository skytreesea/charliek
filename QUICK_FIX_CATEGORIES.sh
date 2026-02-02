#!/bin/bash
# 게시글 카테고리 수정 스크립트
# 사용법: fly ssh console에서 실행

echo "Rails console에 접속하여 다음 명령을 실행하세요:"
echo ""
echo "RAILS_ENV=production bin/rails console"
echo ""
echo "그 다음 다음 코드를 복사해서 붙여넣기:"
echo ""
cat << 'RUBY_CODE'
# 카테고리 수정
Post.where(category: nil).update_all(category: "주식")
Post.where(category: "").update_all(category: "주식")
Post.where("category LIKE ?", "주식%").where.not(category: "주식").update_all(category: "주식")
Post.where.not(category: ["주식", "음악", "출판", "Rails", "자유게시판"]).where.not(category: nil).where.not(category: "").update_all(category: "주식")

# 결과 확인
puts "✅ 모든 카테고리 수정 완료!"
puts "주식: #{Post.where(category: '주식').count}개"
puts "음악: #{Post.where(category: '음악').count}개"
puts "출판: #{Post.where(category: '출판').count}개"
puts "Rails: #{Post.where(category: 'Rails').count}개"
puts "자유게시판: #{Post.where(category: '자유게시판').count}개"
RUBY_CODE
