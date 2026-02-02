# 게시글 카테고리 수정 가이드

## 문제
- 기존 게시글이 게시판에 표시되지 않음
- 카테고리가 NULL이거나 "주식/경제" 같은 이전 카테고리로 저장되어 있음
- 수정 시 카테고리가 업데이트되지 않음

## 해결 방법

### 방법 1: Rails Console에서 직접 실행 (권장)

Fly.io 서버에 접속하여 Rails console에서 직접 실행:

```bash
fly ssh console
```

**중요**: 일반 쉘이 아닌 Rails console에 접속해야 합니다!

콘솔에서 다음 명령을 실행:

```bash
# Rails console 접속
RAILS_ENV=production bin/rails console
```

또는

```bash
RAILS_ENV=production rails console
```

Rails console이 시작되면 (`irb(main):001:0>` 같은 프롬프트가 나타남) 다음 Ruby 코드를 실행:

```ruby
# 1. 현재 상태 확인
puts "=== 현재 상태 ==="
puts "전체 게시글: #{Post.count}개"
puts "NULL 카테고리: #{Post.where(category: nil).count}개"
puts "빈 문자열 카테고리: #{Post.where(category: '').count}개"
puts "주식 카테고리: #{Post.where(category: '주식').count}개"
puts "주식/경제 카테고리: #{Post.where("category LIKE ?", '주식%').count}개"
puts "모든 카테고리 값: #{Post.distinct.pluck(:category).compact.reject(&:blank?).inspect}"

# 2. NULL 카테고리를 "주식"으로 변경
fixed_null = Post.where(category: nil).update_all(category: "주식")
puts "✅ NULL 카테고리 수정: #{fixed_null}개"

# 3. 빈 문자열 카테고리를 "주식"으로 변경
fixed_empty = Post.where(category: "").update_all(category: "주식")
puts "✅ 빈 문자열 카테고리 수정: #{fixed_empty}개"

# 4. "주식/경제" 같은 이전 카테고리를 "주식"으로 변경
fixed_old = Post.where("category LIKE ?", "주식%").where.not(category: "주식").update_all(category: "주식")
puts "✅ 이전 카테고리 수정: #{fixed_old}개"

# 5. 유효하지 않은 카테고리를 "주식"으로 변경
valid_categories = ["주식", "음악", "출판", "Rails", "자유게시판"]
invalid_posts = Post.where.not(category: valid_categories).where.not(category: nil).where.not(category: "")
fixed_invalid = invalid_posts.update_all(category: "주식")
puts "✅ 유효하지 않은 카테고리 수정: #{fixed_invalid}개"

# 6. 최종 확인
puts "\n=== 최종 상태 ==="
valid_categories.each do |cat|
  count = Post.where(category: cat).count
  puts "#{cat}: #{count}개"
end
puts "NULL: #{Post.where(category: nil).count}개"
```

### 방법 2: 한 번에 실행 (Rails Console에서 복사해서 붙여넣기)

**먼저 Rails console에 접속하세요:**
```bash
fly ssh console
RAILS_ENV=production bin/rails console
```

Rails console 프롬프트(`irb(main):001:0>`)가 나타나면 다음 코드를 복사해서 붙여넣기:

```ruby
# 한 번에 실행
Post.where(category: nil).update_all(category: "주식")
Post.where(category: "").update_all(category: "주식")
Post.where("category LIKE ?", "주식%").where.not(category: "주식").update_all(category: "주식")
Post.where.not(category: ["주식", "음악", "출판", "Rails", "자유게시판"]).where.not(category: nil).where.not(category: "").update_all(category: "주식")
puts "✅ 모든 카테고리 수정 완료!"
puts "주식: #{Post.where(category: '주식').count}개"
puts "음악: #{Post.where(category: '음악').count}개"
puts "출판: #{Post.where(category: '출판').count}개"
puts "Rails: #{Post.where(category: 'Rails').count}개"
puts "자유게시판: #{Post.where(category: '자유게시판').count}개"
```

**완료 후 `exit`를 입력하여 Rails console을 종료하세요.**

## 확인 방법

수정 후 게시판 페이지에서 확인:
- `/posts?category=주식` - 주식 게시판에 모든 게시글이 표시되는지 확인
- 각 카테고리별로 게시글이 표시되는지 확인

## 예방 조치

코드에서 이미 다음 조치를 취했습니다:
1. 카테고리 필터링 시 "주식/경제" 같은 이전 카테고리도 "주식"으로 매핑
2. 수정 폼에서 NULL 카테고리를 기본값으로 설정
3. Update 시 빈 카테고리를 기본값으로 설정
