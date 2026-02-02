#!/bin/bash
# Fly.io 서버에서 "문화" 카테고리 게시글 확인 스크립트
# 사용법: 
#   1. 이 스크립트를 서버에 업로드: fly ssh sftp shell (또는 다른 방법)
#   2. 실행: fly ssh console -C "RAILS_ENV=production bin/rails runner /rails/check_culture_posts.rb"

echo "Fly.io 서버에서 문화 카테고리 확인 중..."
fly ssh console -C "bash -c 'RAILS_ENV=production bin/rails runner \"puts \\\"=== 문화 카테고리 확인 ===\\\"; puts \\\"문화 카테고리 게시글 수: #{Post.where(category: \\\"문화\\\").count}개\\\"; puts \\\"모든 카테고리: #{Post.distinct.pluck(:category).compact.sort.inspect}\\\"; puts \\\"문화 게시글: #{Post.where(category: \\\"문화\\\").pluck(:id, :title).inspect}\\\"\"'"
