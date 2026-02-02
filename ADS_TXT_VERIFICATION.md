# Google AdSense ads.txt 검증 가이드

## 현재 설정 상태

✅ `public/ads.txt` 파일이 존재하며 내용이 정확합니다.
✅ 프로덕션 환경에서 정적 파일 서빙이 활성화되어 있습니다.
✅ 컨트롤러 라우트가 안전장치로 존재합니다.

## 점검 방법

### 1. 개발 환경에서 테스트

```bash
# Rails 서버 실행 후
curl -I http://localhost:3000/ads.txt

# 예상 응답:
# HTTP/1.1 200 OK
# Content-Type: text/plain; charset=utf-8
# ...

# 실제 내용 확인
curl http://localhost:3000/ads.txt
```

### 2. 프로덕션 환경에서 테스트

```bash
# 헤더 확인 (200 OK 여부 확인)
curl -I https://MY_DOMAIN/ads.txt

# 실제 내용 확인
curl https://MY_DOMAIN/ads.txt

# 예상 출력:
# google.com, pub-XXXXXXXXXXXXXXXX, DIRECT, f08c47fec0942fa0
```

### 3. Google AdSense 검증

1. Google AdSense 대시보드 접속
2. 사이트 → ads.txt 파일 관리
3. `https://MY_DOMAIN/ads.txt` URL 입력하여 검증

## 문제 해결

### 404 에러가 발생하는 경우

1. **프로덕션 환경 설정 확인**
   ```bash
   # config/environments/production.rb 확인
   # 다음 설정이 true인지 확인:
   config.public_file_server.enabled = true
   ```

2. **환경 변수 확인**
   ```bash
   # 배포 환경에서 확인
   echo $RAILS_SERVE_STATIC_FILES
   # 값이 없거나 false인 경우, production.rb의 설정이 true로 되어 있는지 확인
   ```

3. **웹 서버 설정 확인**
   - Nginx/Apache를 사용하는 경우, `public/` 디렉토리를 직접 서빙하도록 설정되어 있는지 확인
   - Fly.io를 사용하는 경우, Rails가 정적 파일을 서빙하도록 설정되어 있는지 확인

### 컨트롤러 라우트 확인

현재 `routes.rb`에 다음 라우트가 있어서 안전장치로 작동합니다:
```ruby
get "ads.txt", to: "ads_txt#show"
```

이 라우트는 `public/ads.txt`가 서빙되지 않는 경우를 대비한 백업입니다.

## 파일 위치

- 정적 파일: `public/ads.txt`
- 컨트롤러: `app/controllers/ads_txt_controller.rb`
- 라우트: `config/routes.rb` (76번째 줄)
