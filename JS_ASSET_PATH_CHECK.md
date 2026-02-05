# JavaScript·Asset 경로 점검 결과

다른 PC에서 git clone 후에도 JavaScript와 asset이 꼬이지 않도록 점검한 결과입니다. **수정 필요 없음** — 모두 상대/논리 경로 또는 URL 기준으로 이식 가능합니다.

---

## 1. Importmap (`config/importmap.rb`)

| 항목 | 사용 방식 | 이식성 |
|------|-----------|--------|
| `pin "application"` | 엔트리 포인트(기본 `app/javascript/application.js`) | ✅ Rails가 앱 루트 기준으로 해석 |
| `pin "chord_player", to: "chord_player.js"` | `app/javascript/chord_player.js`에 대한 논리명 | ✅ 상대 경로(프로젝트 내) |
| `pin_all_from "app/javascript/controllers", under: "controllers"` | `app/javascript/controllers` 디렉터리 매핑 | ✅ 프로젝트 루트 기준 상대 경로 |
| Turbo, Stimulus, Tone.js | CDN 또는 vendored 경로 | ✅ 절대 URL 또는 앱 내 상대 경로 |

---

## 2. JavaScript 소스 (`app/javascript/`)

- **import 경로:** `import "controllers"`, `import "chord_player"`, `import "@hotwired/..."` 등 **논리명만 사용**. 파일시스템 절대경로 없음.
- **Node/브라우저 전용 경로:** `__dirname`, `process.cwd()`, `/home/`, `C:\`, `file://` 등 **사용처 없음**.

---

## 3. 레이아웃·에셋 로딩 (`app/views/layouts/application.html.erb`)

- `stylesheet_link_tag "tailwind"` → asset 파이프라인에서 `app/assets/tailwind/application.css` 등으로 해석. ✅
- `javascript_importmap_tags` → importmap 기준으로 스크립트 생성. ✅
- `javascript_include_tag "https://..."`, `"chartkick"` → 절대 URL 또는 gem/asset 이름. ✅

---

## 4. 정적 리소스 URL (뷰·컨트롤러)

- `/icon.png`, `request.base_url + "/icon.png"` → **사이트 루트 기준 URL**이므로 호스트만 맞으면 동작. ✅
- `rails_blob_path(...)` → Rails 라우트 기반 URL. ✅

---

## 5. Tailwind (`tailwind.config.js`)

- `content: ["./app/views/**/*.html.erb", "./app/helpers/**/*.rb", ...]` → **프로젝트 루트 기준 상대 경로**. 빌드 시 보통 프로젝트 루트에서 실행되므로 이식 가능. ✅

---

## 정리

JavaScript·stylesheet·asset 관련 경로는 모두 **상대경로·논리명·URL 기준**으로만 사용되어 있어, git으로 옮긴 뒤 다른 컴퓨터에서도 꼬이지 않습니다. 별도 수정 없이 그대로 두면 됩니다.
