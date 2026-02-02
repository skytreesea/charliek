#!/bin/bash
# Clawdbot 설치 스크립트 (WSL Ubuntu)
# 사용법: bash install_clawdbot.sh

set -e  # 오류 발생 시 중단

echo "=== Clawdbot 설치 스크립트 시작 ==="
echo ""

# 1. Node.js 확인
echo "[1/4] Node.js 설치 여부 확인..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v)
    echo "✓ Node.js가 이미 설치되어 있습니다: $NODE_VERSION"
    
    # 버전 체크 (v18 이상 권장)
    MAJOR_VERSION=$(echo $NODE_VERSION | sed 's/v\([0-9]*\).*/\1/')
    if [ "$MAJOR_VERSION" -lt 18 ]; then
        echo "⚠ 경고: Node.js 버전이 낮습니다 (v18 이상 권장). NVM으로 업그레이드하세요."
    fi
else
    echo "✗ Node.js가 설치되어 있지 않습니다."
    echo ""
    echo "[1.1] NVM 설치 중..."
    
    # NVM 설치
    if [ ! -d "$HOME/.nvm" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    else
        echo "✓ NVM이 이미 설치되어 있습니다."
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi
    
    echo ""
    echo "[1.2] Node.js v22 설치 중..."
    nvm install 22
    nvm use 22
    nvm alias default 22
    
    echo "✓ Node.js 설치 완료: $(node -v)"
fi

echo ""
echo "[2/4] npm 확인..."
if command -v npm &> /dev/null; then
    echo "✓ npm: $(npm -v)"
else
    echo "✗ npm이 없습니다. Node.js 재설치가 필요합니다."
    exit 1
fi

echo ""
echo "[3/4] Clawdbot 설치 중..."
echo "공식 설치 스크립트 실행..."
curl -fsSL https://molt.bot/install.sh | bash

echo ""
echo "[4/4] 설치 확인..."
if command -v clawdbot &> /dev/null; then
    echo "✓ Clawdbot 설치 완료!"
    echo ""
    echo "다음 단계:"
    echo "  1. 온보딩 실행: clawdbot onboard --install-daemon"
    echo "  2. Gateway 상태 확인: clawdbot gateway status"
    echo "  3. 대시보드 열기: clawdbot dashboard"
    echo ""
    echo "휴대폰 설정은 MOLTBOT_SETUP_GUIDE.md 파일을 참고하세요."
else
    echo "⚠ 경고: clawdbot 명령어를 찾을 수 없습니다."
    echo "PATH에 추가가 필요할 수 있습니다. 새 터미널을 열거나 다음을 실행하세요:"
    echo "  source ~/.bashrc"
    echo "  export PATH=\"\$(npm prefix -g)/bin:\$PATH\""
fi

echo ""
echo "=== 설치 스크립트 완료 ==="
