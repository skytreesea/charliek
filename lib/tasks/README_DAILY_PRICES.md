# Daily Prices Import Guide

## 개요
M7 종목(AAPL, MSFT, GOOGL, AMZN, META, TSLA, NVDA)의 최근 5년치 일별 종가 데이터를 Yahoo Finance에서 다운로드한 CSV 파일로부터 가져와서 DailyPrice 테이블에 저장하는 rake task입니다.

## 사용 방법

### 1. CSV 파일 다운로드

Yahoo Finance에서 각 종목의 CSV 파일을 다운로드하세요:

1. **AAPL 예시**:
   - https://finance.yahoo.com/quote/AAPL/history 방문
   - 기간 선택: "5Y" (5년)
   - "Download" 버튼 클릭
   - 파일명을 `AAPL.csv`로 저장

2. **다른 종목들도 동일하게**:
   - MSFT: https://finance.yahoo.com/quote/MSFT/history
   - GOOGL: https://finance.yahoo.com/quote/GOOGL/history
   - AMZN: https://finance.yahoo.com/quote/AMZN/history
   - META: https://finance.yahoo.com/quote/META/history
   - TSLA: https://finance.yahoo.com/quote/TSLA/history
   - NVDA: https://finance.yahoo.com/quote/NVDA/history

### 2. CSV 파일 저장 위치

다운로드한 CSV 파일들을 다음 위치에 저장하세요:

```
public/data/yahoo_finance/
├── AAPL.csv
├── MSFT.csv
├── GOOGL.csv
├── AMZN.csv
├── META.csv
├── TSLA.csv
└── NVDA.csv
```

### 3. 데이터베이스 마이그레이션 실행

```bash
rails db:migrate
```

### 4. 데이터 임포트 실행

```bash
rails daily_prices:import
```

### 5. 통계 확인

```bash
rails daily_prices:stats
```

### 6. 데이터 삭제 (필요시)

```bash
rails daily_prices:clear
```

## CSV 파일 형식

Yahoo Finance CSV 파일은 다음 형식을 따릅니다:

```csv
Date,Open,High,Low,Close,Adj Close,Volume
2024-01-18,150.25,152.30,149.80,151.20,151.20,50000000
2024-01-17,149.50,150.80,148.90,150.25,150.25,48000000
...
```

## 주의사항

- 최근 5년 데이터만 처리됩니다 (5년 이전 데이터는 자동으로 제외)
- 중복 데이터는 자동으로 건너뜁니다
- 같은 날짜의 데이터가 이미 있으면 가격이 업데이트됩니다
- CSV 파일이 없으면 해당 종목은 건너뜁니다

## 문제 해결

### CSV 파일을 찾을 수 없다는 오류
- `public/data/yahoo_finance/` 디렉토리가 존재하는지 확인
- 파일명이 정확한지 확인 (대문자: AAPL.csv, MSFT.csv 등)
- 파일이 올바른 위치에 있는지 확인

### 데이터가 임포트되지 않음
- CSV 파일 형식이 올바른지 확인
- Date 컬럼이 첫 번째 컬럼인지 확인
- Close 또는 Adj Close 컬럼이 있는지 확인
