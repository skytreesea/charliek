# MoltBot 빠른 설치 가이드 (WSL)

## 🚀 빠른 시작 (3단계)

### Step 1: WSL 터미널 열기
Windows에서 WSL Ubuntu 터미널을 엽니다.

### Step 2: 설치 스크립트 실행
```bash
cd ~/projects/charliek
bash install_clawdbot.sh
```

또는 수동으로:

```bash
# 1. NVM 설치 (Node.js가 없을 경우)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
source ~/.bashrc

# 2. Node.js v22 설치
nvm install 22
nvm use 22

# 3. MoltBot 설치
curl -fsSL https://molt.bot/install.sh | bash
```

### Step 3: 온보딩 실행
```bash
clawdbot onboard --install-daemon
```

---

## 📱 휴대폰 설정

### WhatsApp 사용 시

1. **PC에서 QR 코드 생성**
   ```bash
   clawdbot channels login
   ```

2. **휴대폰에서**
   - WhatsApp 열기
   - 설정 → 연결된 기기
   - "기기 연결" 선택
   - 터미널에 표시된 **QR 코드 스캔**

3. **첫 메시지 후 페어링 승인**
   ```bash
   clawdbot pairing list whatsapp
   clawdbot pairing approve whatsapp <코드>
   ```

### Telegram 사용 시

1. **봇 생성**
   - Telegram에서 [@BotFather](https://t.me/BotFather) 검색
   - `/newbot` 입력
   - 봇 이름과 사용자명 설정
   - **API 토큰** 복사

2. **온보딩 시 토큰 입력** 또는 설정 파일에 추가

3. **봇에게 첫 DM 보내기**
   - 봇에게 메시지 전송
   - **페어링 코드** 확인

4. **PC에서 승인**
   ```bash
   clawdbot pairing list telegram
   clawdbot pairing approve telegram <코드>
   ```

### Discord 사용 시

1. **봇 생성**
   - [Discord Developer Portal](https://discord.com/developers/applications) 접속
   - 새 애플리케이션 생성
   - Bot 탭에서 봇 추가
   - **토큰** 복사

2. **온보딩 시 토큰 입력**

3. **서버에 봇 초대 후 DM 보내기**
   - 봇에게 DM 전송
   - **페어링 코드** 확인

4. **PC에서 승인**
   ```bash
   clawdbot pairing list discord
   clawdbot pairing approve discord <코드>
   ```

---

## ✅ 확인 명령어

```bash
# 상태 확인
clawdbot status
clawdbot health

# 페어링 대기 목록
clawdbot pairing list

# 대시보드 열기
clawdbot dashboard
# 또는 브라우저에서: http://127.0.0.1:18789/
```

---

## 🔧 문제 해결

### Node.js를 찾을 수 없음
```bash
# NVM 환경 변수 로드
source ~/.bashrc
# 또는
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

### clawdbot 명령어를 찾을 수 없음
```bash
# npm 전역 경로를 PATH에 추가
export PATH="$(npm prefix -g)/bin:$PATH"
# 영구 적용: ~/.bashrc에 추가
echo 'export PATH="$(npm prefix -g)/bin:$PATH"' >> ~/.bashrc
```

### Windows에서 WSL Node 확인
```powershell
wsl -e bash -ic "node -v"
```

---

## 📚 상세 가이드

더 자세한 내용은 `MOLTBOT_SETUP_GUIDE.md` 파일을 참고하세요.
