# 경로 이식성 점검 및 수정 계획서

다른 컴퓨터에서 git clone 후 실행 시, 로컬 절대경로로 인한 오류를 막기 위한 점검 결과와 수정 계획입니다.

---

## 1. 점검 결과 요약

### 1.1 이미 이식 가능한 부분 (수정 불필요)

| 구분 | 파일/위치 | 사용 방식 | 비고 |
|------|-----------|-----------|------|
| DB 경로 | `config/database.yml` | `storage/development.sqlite3` 등 | Rails가 `Rails.root` 기준으로 해석 |
| 스토리지 | `config/storage.yml` | `Rails.root.join("tmp/storage")`, `Rails.root.join("storage")` | 프로젝트 루트 기준 |
| .env 로드 | `app/services/gemini_service.rb` | `Rails.root.join(".env")` | 프로젝트 루트 기준 |
| 정적 파일 | `app/controllers/ads_txt_controller.rb` | `Rails.root.join('public', 'ads.txt')` | 상대 경로 |
| Favicon | `app/controllers/favicon_controller.rb` | `Rails.root.join('public', 'icon.png')` | 상대 경로 |
| CSV 디렉터리 | `app/controllers/backtests_controller.rb` | `Rails.root.join('public', 'data', 'yahoo_finance')` | 상대 경로 |
| 캐시 파일 | `config/environments/development.rb` | `Rails.root.join("tmp/caching-dev.txt")` | 상대 경로 |
| 부트스트랩 | `config/boot.rb` | `File.expand_path("../Gemfile", __dir__)` | Rails 표준 |
| 미들웨어 | `config/application.rb` | `require_relative '../lib/canonical_domain_middleware'` | 프로젝트 내 상대경로 |

**결론:** 애플리케이션 코드와 설정은 **절대경로를 사용하지 않으며**, `Rails.root` 또는 프로젝트 내 상대경로만 사용하고 있어 다른 PC에서도 그대로 동작합니다.

---

### 1.2 수정이 필요한 부분 (문서·스크립트 예시의 절대경로)

다른 컴퓨터에서 문서를 따라 할 때, **문서에 적힌 경로가 해당 PC와 맞지 않아** 오류가 나거나 잘못된 디렉터리로 이동할 수 있는 위치입니다.

| 우선순위 | 파일 | 위치(대략) | 현재 내용 | 문제 |
|----------|------|------------|-----------|------|
| 높음 | `DOMAIN_SETUP.md` | 8행 근처 | `cd /home/kch/projects/charliek` | Linux 사용자명/경로 고정 |
| 높음 | `OLLAMA_CLAWDBOT_SETUP.md` | 13행, 14행 | `cd ~/projects/charliek` | 사용자마다 프로젝트 위치 다름 |
| 높음 | `MOLTBOT_QUICK_START.md` | 10행, 11행 | `cd ~/projects/charliek` | 동일 |
| 중간 | `PAGY_ISSUE_REPORT.md` | 53행 | `/home/kch/projects/charliek/config/application.rb` | 에러 로그 예시에 절대경로 노출 |
| 낮음 | `DEPLOY_DATA_IMPORT.md` | 16행 등 | `cd /rails/public/data/...` | Fly 컨테이너 **내부** 경로이므로 배포 맥락에서는 정확함. 로컬과 혼동하지 않도록 설명만 보강 가능 |

**참고:**  
- `config/deploy.yml`의 `charliek_storage:/rails/storage`, `asset_path: /rails/public/assets`는 **컨테이너 내부 경로**이므로 배포용으로 유지합니다.  
- `.env`는 프로젝트 루트에서 `Rails.root.join(".env")`로만 참조되므로, 경로 이식성과는 무관합니다. (`.env` 자체는 `.gitignore`로 제외하는 것이 보안상 권장됩니다.)

---

## 2. 수정 계획

### 2.1 DOMAIN_SETUP.md

- **현재:** `cd /home/kch/projects/charliek`
- **수정안:**  
  - 프로젝트 루트로 이동하는 방법을 **경로에 의존하지 않도록** 안내  
  - 예:  
    - `cd /home/kch/projects/charliek`  
    → **"프로젝트 루트 디렉터리로 이동한 뒤"** 또는  
    → **"`cd <프로젝트를 clone한 경로>`"**  
    그리고 필요 시 예시로  
    **`cd "$(git rev-parse --show-toplevel)"`**  
    추가 (git이 있는 경우 항상 동일하게 동작)

### 2.2 OLLAMA_CLAWDBOT_SETUP.md

- **현재:** `cd ~/projects/charliek` 후 `bash install_ollama_clawdbot.sh`
- **수정안:**  
  - "프로젝트 루트에서" 실행한다고 명시  
  - 예:  
    - **"프로젝트 루트 디렉터리에서 다음을 실행하세요."**  
    - **`cd "$(git rev-parse --show-toplevel)"`** (또는 프로젝트 루트로 이동한 뒤)  
    - **`bash install_ollama_clawdbot.sh`**  
  - `~/projects/charliek` 같은 구체 경로는 제거하거나 "예: ~/projects/charliek"처럼 선택적 예시로만 표기

### 2.3 MOLTBOT_QUICK_START.md

- **현재:** `cd ~/projects/charliek` 후 `bash install_clawdbot.sh`
- **수정안:**  
  - OLLAMA 가이드와 동일하게 "프로젝트 루트에서 실행"으로 통일  
  - **`cd "$(git rev-parse --show-toplevel)"`** + **`bash install_clawdbot.sh`**  
  - 구체적인 홈 경로는 제거하거나 예시로만 표기

### 2.4 PAGY_ISSUE_REPORT.md

- **현재:** 오류 메시지 예시에 `/home/kch/projects/charliek/config/application.rb` 포함
- **수정안:**  
  - 예시를 **`config/application.rb:4:in \`<main>\'`** 또는 **`.../config/application.rb:4:in \`<main>\'`** 형태로 일반화  
  - "실제 환경에서는 절대경로가 출력될 수 있음" 정도의 한 줄 설명 추가 (선택)

### 2.5 DEPLOY_DATA_IMPORT.md (선택)

- **현재:** `cd /rails/public/data/yahoo_finance` 등은 Fly **컨테이너 내부** 경로로 올바름
- **수정안:**  
  - 문서 상단 또는 해당 절 근처에  
    **"아래 경로(/rails/...)는 Fly.io 컨테이너 **안**의 경로이며, 로컬 PC 경로와 다릅니다."**  
    라는 문구 한 줄 추가하여 혼동 방지

### 2.6 .env / .env.example (참고)

- **경로 이식성:**  
  - `.env` 파일 위치는 코드에서 `Rails.root.join(".env")`로만 참조되므로 다른 PC에서도 동작합니다.  
- **보안:**  
  - `.env`에 API 키 등이 들어가므로 `.gitignore`에 포함되어 있는지 확인하고, 저장소에는 `.env.example`만 두는 것을 권장합니다.  
  - 이번 계획의 “경로 수정” 범위에는 포함하지 않아도 됩니다.

---

## 3. 작업 순서 제안

1. **DOMAIN_SETUP.md** – `cd` 경로를 "프로젝트 루트" + (선택) `git rev-parse --show-toplevel` 예시로 수정  
2. **OLLAMA_CLAWDBOT_SETUP.md** – 동일 방식으로 프로젝트 루트 이동 안내로 통일  
3. **MOLTBOT_QUICK_START.md** – 동일 방식으로 통일  
4. **PAGY_ISSUE_REPORT.md** – 오류 메시지 예시 경로 일반화  
5. **DEPLOY_DATA_IMPORT.md** – (선택) 컨테이너 경로 설명 한 줄 추가  

---

## 4. 점검 시 사용한 검색 패턴 요약

- 절대경로 후보: `/home/`, `C:\`, `D:\`, `\`, `/Users/`, `kch/projects`, `charliek/`
- 설정·경로 사용: `.env`, `config.`, `PATH`, `path\s*[=:]`, `Rails.root`, `File.join`, `Dir.`, `File.read`, `File.open`, `expand_path`
- 문서·스크립트: `cd\s+`, `mkdir`, `/rails/`, `~/`, `.sh`, `.md`

---

## 5. 결론

- **코드·설정:** 이미 상대경로 및 `Rails.root`만 사용하고 있어 **추가 코드 수정은 필요 없음**.  
- **문서·가이드:** 위 4~5개 문서에서 **로컬 절대경로를 “프로젝트 루트” 또는 `git rev-parse --show-toplevel` 기반 안내로 바꾸면**, 다른 컴퓨터에서 clone 후에도 같은 문서대로 진행할 수 있습니다.  
- 이 계획서대로 수정 후, 필요하면 `PATH_PORTABILITY_PLAN.md`는 프로젝트 루트에 두고 “경로 이식성 점검 결과” 참고용으로 활용하시면 됩니다.
