# MoltBot 설치 가이드 + 휴대폰 설정

[MoltBot](https://docs.molt.bot/)은 Discord, WhatsApp, Telegram 등에서 쓸 수 있는 개인 AI 어시스턴트입니다.

---

## 1. 사전 준비

- **Node.js ≥ 22** (MoltBot 권장: v18/v20 이상, 가능하면 v22)
- **Windows**: **WSL2**(Ubuntu 권장) 사용. 네이티브 Windows는 비공식 지원.

### 1.1 Node 설치 여부 확인

WSL 터미널에서:
```bash
which node
node -v
```
아무 결과도 없으면 미설치.

**Windows PowerShell에서 WSL Node 확인** (환경 변수 반영):
```powershell
wsl -e bash -ic "node -v"
```

### 1.2 NVM으로 Node.js 설치 (권장)

WSL 터미널에서:

**NVM 설치**
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
```

**설정 적용** (터미널 재시작 또는):
```bash
source ~/.bashrc
# zsh 사용 시: source ~/.zshrc
```

**Node.js LTS 설치** (v22 권장)
```bash
nvm install 22
nvm use 22
# 또는 최신 LTS: nvm install --lts
```

**확인**
```bash
node -v   # v22.x 또는 v20.x 등
npm -v
```

### 1.3 (대안) NodeSource로 직접 설치

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs
```

---

## 2. MoltBot 설치

### A) WSL2 Ubuntu / Linux (권장)

```bash
curl -fsSL https://molt.bot/install.sh | bash
```

온보딩 건너뛰기:
```bash
curl -fsSL https://molt.bot/install.sh | bash -s -- --no-onboard
```

### B) Windows PowerShell (Node 설치된 경우)

```powershell
iwr -useb https://molt.bot/install.ps1 | iex
```

### C) npm으로 직접 설치

```bash
npm install -g clawdbot@latest
# 또는
pnpm add -g clawdbot@latest
```

---

## 3. 온보딩 및 서비스 설치

```bash
clawdbot onboard --install-daemon
```

이때 선택하는 것:
- **Gateway**: 로컬 vs 원격
- **인증**: OpenAI OAuth 또는 API 키 (Anthropic는 API 키 권장)
- **채널**: WhatsApp / Telegram / Discord 등
- **데몬**: 백그라운드 서비스 설치 (launchd/systemd)
- **런타임**: **Node** 사용 (WhatsApp/Telegram은 Bun 비권장)

---

## 4. Gateway 확인

```bash
clawdbot gateway status
# 또는 수동 실행
clawdbot gateway --port 18789 --verbose
```

대시보드: **http://127.0.0.1:18789/**

---

## 5. 휴대폰으로 할 일 (채널별)

### A) WhatsApp으로 쓰는 경우

1. 휴대폰에 **WhatsApp** 설치 및 로그인
2. PC 터미널에서:
   ```bash
   clawdbot channels login
   ```
3. 휴대폰에서 **WhatsApp → 설정 → 연결된 기기** 이동
4. **“기기 연결”** 선택 후 표시되는 **QR 코드 스캔**
5. 첫 DM에서 **페어링 코드**가 오면, PC에서 승인:
   ```bash
   clawdbot pairing list whatsapp
   clawdbot pairing approve whatsapp <코드>
   ```

### B) Telegram으로 쓰는 경우

1. 휴대폰에 **Telegram** 설치
2. [@BotFather](https://t.me/BotFather)에서 봇 생성 후 **API 토큰** 복사
3. 온보딩 시 Telegram 토큰 입력하거나, 설정에 수동 추가
4. **봇에게 첫 DM**을 보내면 **페어링 코드** 발급
5. PC에서 승인:
   ```bash
   clawdbot pairing list telegram
   clawdbot pairing approve telegram <코드>
   ```

### C) Discord로 쓰는 경우

1. [Discord Developer Portal](https://discord.com/developers/applications)에서 봇 애플리케이션 생성
2. **Bot** 추가 후 **토큰** 복사
3. 온보딩/설정에 Discord 토큰 입력
4. 서버에 봇 초대 후, 봇에게 **DM** 보내면 **페어링 코드** 발급
5. PC에서:
   ```bash
   clawdbot pairing list discord
   clawdbot pairing approve discord <코드>
   ```

---

## 6. 빠른 확인

```bash
clawdbot status
clawdbot health
clawdbot pairing list   # 채널별 대기 중인 페어링 확인
```

테스트 메시지 (대상이 설정된 경우):
```bash
clawdbot message send --target +821012345678 --message "MoltBot 테스트"
```

---

## 7. 문제 해결

- **`clawdbot`을 찾을 수 없음**: `$(npm prefix -g)/bin`을 `PATH`에 추가
- **WhatsApp/Telegram 연동 오류**: Gateway는 **Node**로 실행 (Bun 사용 X)
- **첫 DM 무응답**: `clawdbot pairing list`로 코드 확인 후 `approve` 필수
- 상세 문서: https://docs.molt.bot/install  
- 트러블슈팅: https://docs.molt.bot/help/troubleshooting
