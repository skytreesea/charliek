#!/bin/bash
# Ollama 설치 + Clawdbot 연동 (WSL Ubuntu)
# 사용법: bash install_ollama_clawdbot.sh

set -e

echo "=== Ollama 설치 및 Clawdbot 연동 ==="
echo ""

# 1. Ollama 설치
echo "[1/4] Ollama 설치 확인..."
if command -v ollama &> /dev/null; then
    echo "✓ Ollama 이미 설치됨: $(ollama --version)"
else
    echo "Ollama 설치 중..."
    curl -fsSL https://ollama.com/install.sh | sh
    echo "✓ Ollama 설치 완료"
fi

# 2. Ollama 서비스 실행 (백그라운드)
echo ""
echo "[2/4] Ollama 서비스 확인..."
if pgrep -x ollama > /dev/null 2>&1; then
    echo "✓ Ollama 서비스 실행 중"
else
    echo "Ollama 서비스 시작 중..."
    ollama serve &
    sleep 3
    if pgrep -x ollama > /dev/null 2>&1; then
        echo "✓ Ollama 서비스 시작됨"
    else
        echo "⚠ Ollama 서비스 자동 시작 실패. 수동 실행: ollama serve"
    fi
fi

# 3. 모델 pull (llama3.3 - Clawdbot용, 권장)
echo ""
echo "[3/4] Ollama 모델 다운로드..."
MODEL="${OLLAMA_MODEL:-llama3.3}"
if ollama list 2>/dev/null | grep -q "$MODEL"; then
    echo "✓ 모델 $MODEL 이미 있음"
else
    echo "모델 $MODEL 다운로드 중... (처음엔 시간 걸림)"
    ollama pull "$MODEL"
    echo "✓ 모델 $MODEL 다운로드 완료"
fi

# 4. Clawdbot 연동 안내
echo ""
echo "[4/4] Clawdbot 연동"
echo ""
echo "다음 명령어로 Clawdbot 기본 모델을 Ollama로 설정하세요:"
echo ""
echo "  clawdbot config set 'agents.defaults.model.primary' 'ollama/${MODEL}:latest'"
echo ""
echo "또는 configure UI:"
echo "  clawdbot configure --section models"
echo "  → Ollama / ${MODEL}:latest 선택"
echo ""
echo "=== 완료 ==="
echo ""
echo "Ollama 모델 목록: ollama list"
echo "다른 모델 예: ollama pull llama3.3  →  clawdbot config set ... 'ollama/llama3.3:latest'"
echo ""
