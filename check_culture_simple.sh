#!/bin/bash
# Fly.io 서버에서 "문화" 카테고리 게시글 확인 (간단 버전)
# 사용법: ./check_culture_simple.sh

echo "Fly.io 서버에서 문화 카테고리 확인 중..."
fly ssh console -C "bash -c 'RAILS_ENV=production bin/rails runner \"puts Post.where(category: \\\"문화\\\").count; puts Post.distinct.pluck(:category).compact.sort.inspect; puts Post.where(category: \\\"문화\\\").pluck(:id, :title).inspect\"'"
