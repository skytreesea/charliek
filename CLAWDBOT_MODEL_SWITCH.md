# Clawdbot 모델 변경 가이드 (GPT → Gemini / 무료 모델)

GPT 무료 토큰을 다 썼다면 **Gemini** 또는 **OpenRouter 무료 모델**로 바꿀 수 있습니다.

---

## 1. Gemini로 변경 (권장 – 이미 쓰고 있으면)

### 1.1 API 키 준비

1. [Google AI Studio](https://aistudio.google.com/apikey) 접속
2. **Create API Key**로 키 생성
3. 키 복사 (예: `AIzaSy...`)

### 1.2 Clawdbot에 Gemini 설정

**방법 A: 온보딩으로 한 번에**
```bash
clawdbot onboard --auth-choice gemini-api-key
```
키 입력하라는 프롬프트에서 `GEMINI_API_KEY` 붙여넣기.

**방법 B: Configure로 모델 섹션만**
```bash
clawdbot configure --section models
```
이후 인터랙티브에서 **Gemini API Key** 선택하고 키 입력.

**방법 C: 환경 변수 + config**
```bash
# 환경 변수 (WSL ~/.bashrc 등)
export GEMINI_API_KEY="AIzaSy..."

# 기본 모델을 Gemini로 설정
clawdbot config set 'agents.defaults.model.primary' 'google/gemini-2.0-flash'
# 또는
clawdbot config set 'agents.defaults.model.primary' 'google/gemini-1.5-flash'
```

### 1.3 사용 가능한 Gemini 모델 예시

| 모델 ID | 비고 |
|--------|------|
| `google/gemini-2.0-flash` | 빠르고 무료 한도 넉넉 |
| `google/gemini-1.5-flash` | 무료 티어 |
| `google/gemini-1.5-pro` | Pro |
| `google/gemini-3-pro-preview` | 최신 (문서 기준) |

**모델 확인:**
```bash
clawdbot models list
```

---

## 2. OpenRouter 무료 모델로 변경

OpenRouter는 **한 개 API 키**로 여러 provider(무료 포함)를 쓸 수 있습니다.

### 2.1 OpenRouter API 키

1. [OpenRouter](https://openrouter.ai/) 가입
2. [Keys](https://openrouter.ai/keys)에서 API Key 생성
3. 무료 크레딧 또는 무료 모델 사용

### 2.2 Clawdbot에 OpenRouter 설정

**온보딩으로 API 키 등록:**
```bash
clawdbot onboard --auth-choice apiKey --token-provider openrouter --token "sk-or-..."
```

**기본 모델을 OpenRouter 무료 모델로:**
```bash
# 예: Google Gemini Flash (OpenRouter 경유)
clawdbot config set 'agents.defaults.model.primary' 'openrouter/google/gemini-2.0-flash-free'

# 예: Meta Llama
clawdbot config set 'agents.defaults.model.primary' 'openrouter/meta-llama/llama-3.3-70b-instruct:free'

# 예: Mistral
clawdbot config set 'agents.defaults.model.primary' 'openrouter/mistralai/mistral-7b-instruct:free'
```

**무료 모델 목록:**  
https://openrouter.ai/models?q=free  
→ `:free` 붙은 ID를 `openrouter/...` 형태로 사용.

---

## 3. Configure UI로 모델만 바꾸기

```bash
clawdbot configure --section models
```

- **Model** 섹션에서 사용할 provider/모델 선택
- **multi-select**로 `agents.defaults.models` allowlist 설정 가능
- 기본(primary) 모델 선택 후 저장

---

## 4. 설정 확인

```bash
# 현재 기본 모델
clawdbot models list

# Gateway/config 상태
clawdbot status
clawdbot health
```

---

## 5. Config 직접 수정 (고급)

설정 파일(예: `~/.clawdbot/...` 또는 gateway `moltbot.json`)에서:

**Gemini:**
```json
{
  "env": { "GEMINI_API_KEY": "AIzaSy..." },
  "agents": {
    "defaults": {
      "model": { "primary": "google/gemini-2.0-flash" }
    }
  }
}
```

**OpenRouter:**
```json
{
  "env": { "OPENROUTER_API_KEY": "sk-or-..." },
  "agents": {
    "defaults": {
      "model": { "primary": "openrouter/google/gemini-2.0-flash-free" }
    }
  }
}
```

편집 후 Gateway 재시작:
```bash
clawdbot gateway stop
clawdbot gateway start
# 또는
clawdbot gateway --port 18789 --verbose
```

---

## 6. 요약

| 목적 | 방법 |
|------|------|
| **Gemini로 바꾸기** | `GEMINI_API_KEY` 설정 후 `agents.defaults.model.primary` = `google/gemini-2.0-flash` 등 |
| **무료 모델 쓸 때** | OpenRouter 가입 → `OPENROUTER_API_KEY` 설정 → `openrouter/.../...:free` 사용 |
| **설정만 바꾸기** | `clawdbot configure --section models` |
| **CLI로 바로 설정** | `clawdbot config set 'agents.defaults.model.primary' 'google/gemini-2.0-flash'` |

Gemini 쓰고 있으면 **1번**만 따라 하면 되고, 다른 상용 무료 모델 쓸 때는 **2번 OpenRouter**를 사용하면 됩니다.
