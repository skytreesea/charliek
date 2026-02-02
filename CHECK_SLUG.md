# Slug 주소 확인 방법

## 1. 브라우저 주소창에서 확인
게시글을 클릭하면 주소창에 slug 기반 URL이 표시됩니다.
- 기존: `https://charliek.kr/posts/3`
- 변경 후: `https://charliek.kr/posts/그린란드-사태에-채권금리가`

## 2. 링크에 마우스 오버
게시글 제목이나 링크에 마우스를 올리면 브라우저 하단 상태바에 slug URL이 표시됩니다.

## 3. Rails 콘솔에서 확인
```bash
bin/rails console

# 모든 게시글의 slug 확인
Post.all.pluck(:id, :title, :slug)

# 특정 게시글의 slug 확인
post = Post.find(3)
puts post.slug
puts post_path(post)  # => "/posts/그린란드-사태에-채권금리가"
```

## 4. 데이터베이스에서 직접 확인
```bash
bin/rails dbconsole

# SQLite에서 확인
SELECT id, title, slug FROM posts LIMIT 10;
```

## 5. 마이그레이션 실행 확인
slug 컬럼이 생성되었는지 확인:
```bash
bin/rails db:migrate:status
```

마이그레이션이 실행되지 않았다면:
```bash
bin/rails db:migrate
```

## 참고
- slug는 제목 기반으로 자동 생성됩니다
- 한글 제목도 지원됩니다 (`parameterize(locale: :ko)`)
- 중복 시 `-2`, `-3` 등이 자동 추가됩니다
