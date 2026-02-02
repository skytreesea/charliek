# Clawdbot 처음부터 다시 설정 + Ollama 선택

설정을 **리셋**한 뒤 온보딩을 다시 돌리고, **Ollama**를 기본 모델로 선택하는 방법입니다.

---

## 0. 준비

- **Ollama** 설치되어 있고 **실행 중**이어야 합니다.
- 사용할 모델 미리 받기:
  ```bash
  ollama pull llama3.1
  ollama list
  ```

---

## 1. Gateway 중지

```bash
clawdbot gateway stop
```

---

## 2. 설정 리셋

**설정만** 지우기 (자격 증명·세션 유지):

```bash
clawdbot reset --scope config --yes
```

**설정 + 자격 증명 + 세션** 모두 지우기 (완전 처음부터):

```bash
clawdbot reset --scope config+creds+sessions --yes
```

- `--yes`: 확인 프롬프트 없이 실행  
- 먼저 `clawdbot reset --dry-run`으로 무엇이 지워질지 확인할 수 있습니다.

---

## 3. 온보딩 다시 실행

```bash
clawdbot onboard --install-daemon
```

위저드가 처음 설정처럼 진행됩니다.

---

## 4. 위저드에서 Ollama 선택하기

### Model / Auth 단계

- **인증**: **Skip** 선택 (Ollama는 API 키 없음).
- **기본 모델**:
  - Ollama가 `http://127.0.0.1:11434`에서 떠 있으면, **감지된 옵션**에 Ollama 모델이 나올 수 있음 → 그중에서 `ollama/llama3.1` 등 선택.
  - 목록에 없으면 **수동 입력**: `ollama/llama3.1` 입력.

### 이후 단계

- **Workspace**: 기본값(`~/clawd`) 그대로 두어도 됨.
- **Gateway**: 포트 18789, 로컬 루프백 등 기본값 유지.
- **Channels**: WhatsApp / Telegram / Discord 등 원하는 채널 설정.
- **Daemon**: `--install-daemon` 사용 시 자동으로 서비스 설치.
- **Skills**: 원하면 선택, 아니면 스킵.

---

## 5. 리셋 없이 위저드만 다시 (기존 설정 수정)

이미 있는 설정을 **유지**한 채 모델만 바꾸려면:

```bash
clawdbot onboard
```

- 기존 설정이 있으면 **Keep / Modify / Reset** 중 선택.
- **Modify** → Model 단계로 가서 Ollama 선택하거나, **Reset** 후 위 4단계처럼 Ollama 선택.

---

## 6. 모델만 Ollama로 바꾸기 (온보딩 생략)

리셋·온보딩 없이 **기본 모델만** Ollama로 변경:

```bash
clawdbot config set 'agents.defaults.model.primary' 'ollama/llama3.1'
clawdbot gateway stop
clawdbot gateway start
```

---

## 7. 확인

```bash
clawdbot models list
clawdbot gateway status
clawdbot health
```

---

## 요약

| 목적 | 명령 |
|------|------|
| **처음부터 다시 + Ollama** | `clawdbot gateway stop` → `clawdbot reset --scope config+creds+sessions --yes` → `clawdbot onboard --install-daemon` → Model 단계에서 **Skip** + `ollama/llama3.1` |
| **설정만 리셋** | `clawdbot reset --scope config --yes` |
| **모델만 Ollama로** | `clawdbot config set 'agents.defaults.model.primary' 'ollama/llama3.1'` 후 Gateway 재시작 |

Ollama는 **반드시** `ollama serve`(또는 systemd 등)로 실행 중이어야 위저드에서 감지되고, Clawdbot이 정상 동작합니다.
