# Ollama 로컬 설치 + Clawdbot 연동 가이드

로컬에서 **Ollama**로 LLM을 돌리고, **Clawdbot** 기본 모델을 Ollama로 바꾸는 방법입니다.  
API 키 없이 **완전 무료**, 한도 제한 없이 쓸 수 있습니다.

---

## 1. Ollama 설치 (WSL Ubuntu)

### 방법 A: 설치 스크립트 (권장)

```bash
cd ~/projects/charliek
bash install_ollama_clawdbot.sh
```

### 방법 B: 수동 설치

```bash
# Ollama 설치
curl -fsSL https://ollama.com/install.sh | sh

# Ollama 서비스 실행 (백그라운드)
ollama serve &

# 모델 다운로드 (처음 한 번)
ollama pull llama3.1
# 또는 더 큰 모델: ollama pull llama3.3
```

### 확인

```bash
ollama --version
ollama list
```

---

## 2. Clawdbot에 Ollama 연동

### 처음부터 설정 리셋 후 Ollama 선택

설정을 **완전히 지우고** 온보딩을 다시 돌린 뒤, 위저드에서 Ollama를 고르려면:

```bash
clawdbot gateway stop
clawdbot reset --scope config+creds+sessions --yes
clawdbot onboard --install-daemon
```

Model/Auth 단계에서 **Skip** → 기본 모델 `ollama/llama3.1` (또는 감지된 Ollama 모델) 선택.  
자세한 단계는 **`CLAWDBOT_RESET_OLLAMA.md`** 참고.

---

### 방법 A: config set (CLI)

```bash
# 기본 모델을 Ollama로 설정
clawdbot config set 'agents.defaults.model.primary' 'ollama/llama3.1'
```

다른 모델 쓰려면 `ollama/모델이름` 형식으로 바꾸면 됩니다.

| Ollama 모델 | Clawdbot 모델 ID |
|-------------|------------------|
| `llama3.2:3b` | `ollama/llama3.2:3b` |
| `llama3.2:1b` | `ollama/llama3.2:1b` |
| `llama3.3` | `ollama/llama3.3` |
| `llama3.1` | `ollama/llama3.1` |
| `mistral` | `ollama/mistral` |
| `qwen2.5` | `ollama/qwen2.5` |

### 방법 B: Configure UI

```bash
clawdbot configure --section models
```

인터랙티브에서 **Ollama** 선택 후 사용할 모델 지정.

### 방법 C: 설정 파일 직접 수정

Gateway 설정(예: `~/.clawdbot/` 또는 `moltbot.json`)에 다음 추가:

```json
{
  "agents": {
    "defaults": {
      "model": { "primary": "ollama/llama3.1" }
    }
  }
}
```

---

## 3. Ollama 서비스 유지

Ollama는 `http://127.0.0.1:11434` 에서 동작합니다. Clawdbot이 **같은 머신**에서 돌면 자동으로 사용합니다.

### 수동 실행

```bash
ollama serve
```

백그라운드로 두려면:

```bash
nohup ollama serve > /tmp/ollama.log 2>&1 &
```

### systemd (WSL)

```bash
# 서비스 파일 (일반적으로 설치 시 자동 등록)
sudo systemctl status ollama
sudo systemctl start ollama
sudo systemctl enable ollama
```

---

## 4. 모델 추가 / 변경

```bash
# 모델 다운로드
ollama pull llama3.3
ollama pull mistral
ollama pull qwen2.5

# 목록 확인
ollama list

# Clawdbot 기본 모델 변경
clawdbot config set 'agents.defaults.model.primary' 'ollama/llama3.3'
```

---

## 5. 확인

```bash
# Ollama 동작 확인
curl -s http://127.0.0.1:11434/api/tags | head -20

# Clawdbot 모델 확인
clawdbot models list

# Gateway 재시작 (설정 변경 후)
clawdbot gateway stop
clawdbot gateway start
# 또는
clawdbot gateway --port 18789 --verbose
```

---

## 6. 추천 모델 (용도별)

| 모델 | 용도 | RAM 대략 |
|------|------|----------|
| `llama3.2:1b` | 최소 사양, 빠름 | ~2GB |
| `llama3.2:3b` | 가벼운 대화 | ~4GB |
| `llama3.3` | 균형 | ~8GB |
| `mistral` | 영어/코드 | ~6GB |
| `qwen2.5:7b` | 다국어 | ~8GB |

---

## 7. 문제 해결

### `ollama`를 찾을 수 없음

- PATH에 Ollama 포함 여부 확인.
- 재설치: `curl -fsSL https://ollama.com/install.sh | sh`

### Clawdbot이 Ollama 응답 안 함

- Ollama 실행 여부: `pgrep -x ollama`
- `ollama serve` 후 `curl http://127.0.0.1:11434/api/tags` 로 확인
- Clawdbot과 **같은 호스트**에서 Ollama가 돌아가는지 확인

### 특정 모델 429 / timeout

- `ollama pull <모델>` 로 해당 모델 받았는지 확인
- `ollama list` 에 있는 이름과 `ollama/모델이름` 이 일치하는지 확인

---

## 8. 요약

```bash
# 설치
curl -fsSL https://ollama.com/install.sh | sh
ollama serve &
ollama pull llama3.1

# Clawdbot 연동
clawdbot config set 'agents.defaults.model.primary' 'ollama/llama3.1'

# 확인
clawdbot models list
clawdbot gateway --port 18789 --verbose
```

이후 WhatsApp 등 채널에서는 기존처럼 Clawdbot을 쓰면 되고, 백엔드만 Ollama로 동작합니다.
