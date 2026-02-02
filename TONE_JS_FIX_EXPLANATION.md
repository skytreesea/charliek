# Tone.js CDN 오류 해결 가이드

## 발생한 오류 분석

### 1. **404 오류 (핵심 문제)**
```
cdn.jsdelivr.net/npm/tone@14.8.49/build/esm/core/Global:1 Failed to load resource: 404
```

**원인:**
- `/build/esm/index.js` 경로가 존재하지 않음
- Tone.js의 ESM 모듈 구조가 jsdelivr에서 제대로 해석되지 않음
- 내부 모듈들(`core/Global`, `classes`, `version` 등)의 상대 경로 해석 실패

### 2. **Stimulus 컨트롤러 로딩 실패**
```
Failed to register controller: guitar-player
TypeError: Failed to fetch dynamically imported module
```

**원인:**
- Tone.js가 로드되지 않아 `import * as Tone from "tone"` 구문이 실패
- 컨트롤러 파일 자체가 로드되지 않음

### 3. **Preload 경고 (무시 가능)**
- CSS, JS 파일의 preload 경고는 성능 최적화 관련 경고일 뿐, 기능에는 영향 없음
- ads 관련 403 오류는 광고 차단기 또는 네트워크 문제로 무시 가능

## 해결 방법

### ✅ 적용한 수정사항

**importmap.rb 변경:**
```ruby
# 변경 전 (잘못된 경로)
pin "tone", to: "https://cdn.jsdelivr.net/npm/tone@14.8.49/build/esm/index.js"

# 변경 후 (올바른 경로 - UMD 번들)
pin "tone", to: "https://cdn.jsdelivr.net/npm/tone@14.8.49/build/Tone.js"
```

### UMD 번들 vs ESM 모듈

**UMD 번들 (`Tone.js`):**
- ✅ 단일 파일로 모든 기능 포함
- ✅ importmap과 호환성 좋음
- ✅ CDN에서 안정적으로 로드됨
- ⚠️ 전역 변수로도 사용 가능 (`window.Tone`)

**ESM 모듈 (`esm/index.js`):**
- ❌ 내부 모듈 의존성 문제로 CDN에서 로드 실패
- ❌ 상대 경로 해석 문제
- ✅ 트리 쉐이킹 가능 (번들 크기 최적화)

## 추가 확인 사항

### 1. 브라우저 콘솔 확인
수정 후 브라우저를 새로고침하고 콘솔에서 확인:
- `[GuitarPlayer]` 로그가 나타나는지
- Tone.js 관련 오류가 사라졌는지

### 2. Network 탭 확인
브라우저 개발자 도구의 Network 탭에서:
- `Tone.js` 파일이 200 상태로 로드되는지 확인
- 파일 크기가 약 500KB 이상인지 확인 (정상 로드)

### 3. 대안 방법 (위 방법이 안 될 경우)

**옵션 1: unpkg 사용**
```ruby
pin "tone", to: "https://unpkg.com/tone@14.8.49/build/Tone.js"
```

**옵션 2: 로컬 설치 (권장 - 프로덕션 환경)**
```bash
bin/importmap pin tone --download
```

## 예상 결과

수정 후:
1. ✅ Tone.js가 정상적으로 로드됨
2. ✅ `guitar-player` 컨트롤러가 등록됨
3. ✅ 버튼 클릭 시 콘솔에 로그가 나타남
4. ✅ 기타 사운드가 재생됨

## 문제가 계속되면

1. 브라우저 캐시 완전 삭제 (Ctrl+Shift+Delete)
2. Rails 서버 재시작
3. 브라우저 콘솔의 정확한 오류 메시지 확인
