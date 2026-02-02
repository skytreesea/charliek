# MoltBot 실행 및 WhatsApp 연결 가이드

## 🚀 MoltBot 시작하기

### 1. Gateway 상태 확인
```bash
clawdbot gateway status
```

### 2. Gateway 시작 (중지되어 있을 경우)

**방법 A: 백그라운드 서비스로 실행 (권장)**
```bash
# 서비스가 설치되어 있다면 자동으로 시작됨
clawdbot gateway status

# 서비스가 없다면 설치
clawdbot onboard --install-daemon
```

**방법 B: 수동으로 실행**
```bash
clawdbot gateway --port 18789 --verbose
```

### 3. Gateway 확인
브라우저에서 열기:
```
http://127.0.0.1:18789/
```

또는 명령어로:
```bash
clawdbot dashboard
```

---

## 📱 WhatsApp 연결하기

### Step 1: WhatsApp 로그인 시작
```bash
clawdbot channels login
```

이 명령어를 실행하면 터미널에 **QR 코드**가 표시됩니다.

### Step 2: 휴대폰에서 QR 코드 스캔

1. **휴대폰에서 WhatsApp 열기**
2. **설정** (우측 하단 점 3개 또는 설정 아이콘)
3. **연결된 기기** (Linked Devices) 선택
4. **"기기 연결"** 또는 **"Link a Device"** 선택
5. 터미널에 표시된 **QR 코드를 스캔**

### Step 3: 첫 메시지 후 페어링 승인

WhatsApp에서 봇에게 첫 메시지를 보내면, **페어링 코드**가 생성됩니다.

**대기 중인 페어링 확인:**
```bash
clawdbot pairing list whatsapp
```

**페어링 승인:**
```bash
clawdbot pairing approve whatsapp <코드>
```

예시:
```bash
clawdbot pairing approve whatsapp ABC123
```

---

## ✅ 연결 확인

### 상태 확인
```bash
# 전체 상태
clawdbot status

# Gateway 건강 상태
clawdbot health

# 연결된 채널 확인
clawdbot channels
```

### 테스트 메시지
WhatsApp에서 봇에게 메시지를 보내면 자동으로 응답합니다.

---

## 💻 컴퓨터에서 실시간으로 대화 보기

### 방법 1: 웹 대시보드 (가장 쉬움, 권장)

**대시보드 열기:**
```bash
clawdbot dashboard
```

또는 브라우저에서 직접 접속:
```
http://127.0.0.1:18789/
```

대시보드에서:
- 실시간으로 모든 메시지 확인 가능
- WhatsApp 대화 목록 보기
- 메시지 전송 및 수신 내역 확인
- 세션 및 채널 상태 모니터링

### 방법 2: 터미널 로그 실시간 확인

**실시간 로그 보기:**
```bash
# 모든 로그 실시간 확인
clawdbot logs --follow

# 또는 특정 채널만 필터링
clawdbot logs --follow --channel whatsapp
```

**verbose 모드로 Gateway 실행 (더 자세한 로그):**
```bash
clawdbot gateway --port 18789 --verbose
```

### 방법 3: TUI (Terminal UI) 사용

**터미널 기반 UI 열기:**
```bash
clawdbot tui
```

이 명령어로 터미널에서 직접 대화를 보고 관리할 수 있습니다.

### 방법 4: 세션 및 메시지 확인

**최근 메시지 확인:**
```bash
# 세션 목록 보기
clawdbot sessions

# 특정 세션의 메시지 보기
clawdbot sessions <session-id>
```

**채널별 메시지 확인:**
```bash
# WhatsApp 채널 상태 및 메시지
clawdbot channels whatsapp
```

---

## 🔧 문제 해결

### Gateway가 시작되지 않을 때
```bash
# 로그 확인
clawdbot logs

# Gateway 재시작
clawdbot gateway stop
clawdbot gateway start
```

### WhatsApp QR 코드가 표시되지 않을 때
```bash
# 채널 상태 확인
clawdbot channels

# WhatsApp 재연결
clawdbot channels login whatsapp
```

### 페어링 코드를 찾을 수 없을 때
```bash
# 모든 대기 중인 페어링 확인
clawdbot pairing list

# 특정 채널의 페어링만 확인
clawdbot pairing list whatsapp
```

### Gateway가 이미 실행 중일 때
```bash
# 실행 중인 프로세스 확인
clawdbot gateway status

# 이미 실행 중이면 그냥 사용하면 됩니다
```

---

## 📝 빠른 참조 명령어

```bash
# Gateway 시작
clawdbot gateway --port 18789 --verbose

# WhatsApp 로그인
clawdbot channels login

# 페어링 확인 및 승인
clawdbot pairing list whatsapp
clawdbot pairing approve whatsapp <코드>

# 상태 확인
clawdbot status
clawdbot health

# 실시간 대화 보기
clawdbot dashboard          # 웹 대시보드 (권장)
clawdbot tui                # 터미널 UI
clawdbot logs --follow      # 실시간 로그

# 대시보드 열기
clawdbot dashboard
```

---

## 💡 팁

- Gateway는 백그라운드에서 계속 실행되도록 설정하는 것이 좋습니다 (`--install-daemon`)
- WhatsApp 연결은 한 번만 하면 됩니다 (세션이 유지되는 한)
- QR 코드는 약 1-2분 내에 스캔해야 합니다
- 첫 DM은 반드시 페어링 승인이 필요합니다 (보안을 위해)
- **실시간 대화 보기**: `clawdbot dashboard`로 웹 브라우저에서 가장 편하게 확인 가능
- 대시보드는 `http://127.0.0.1:18789/`에서 항상 접근 가능합니다
