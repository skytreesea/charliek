# CSV 파일 다운로드 가이드

## 문제 상황
현재 DailyPrice 테이블에 데이터가 없습니다. CSV 파일을 다운로드하여 임포트해야 합니다.

## 해결 방법

### 1단계: 상태 확인
```bash
rails daily_prices:check
```

이 명령어로 다음을 확인할 수 있습니다:
- 테이블 존재 여부
- CSV 파일 존재 여부
- 마이그레이션 상태

### 2단계: CSV 파일 다운로드

각 종목별로 Yahoo Finance에서 CSV 파일을 다운로드하세요:

#### AAPL (Apple)
1. https://finance.yahoo.com/quote/AAPL/history 방문
2. 기간 선택: "MAX" 또는 "5Y" 선택
3. "Download" 버튼 클릭
4. 파일명을 `AAPL.csv`로 변경
5. `public/data/yahoo_finance/` 디렉토리에 저장

#### MSFT (Microsoft)
1. https://finance.yahoo.com/quote/MSFT/history 방문
2. 기간 선택: "MAX" 또는 "5Y" 선택
3. "Download" 버튼 클릭
4. 파일명을 `MSFT.csv`로 변경
5. `public/data/yahoo_finance/` 디렉토리에 저장

#### GOOGL (Google)
1. https://finance.yahoo.com/quote/GOOGL/history 방문
2. 기간 선택: "MAX" 또는 "5Y" 선택
3. "Download" 버튼 클릭
4. 파일명을 `GOOGL.csv`로 변경
5. `public/data/yahoo_finance/` 디렉토리에 저장

#### AMZN (Amazon)
1. https://finance.yahoo.com/quote/AMZN/history 방문
2. 기간 선택: "MAX" 또는 "5Y" 선택
3. "Download" 버튼 클릭
4. 파일명을 `AMZN.csv`로 변경
5. `public/data/yahoo_finance/` 디렉토리에 저장

#### META (Meta/Facebook)
1. https://finance.yahoo.com/quote/META/history 방문
2. 기간 선택: "MAX" 또는 "5Y" 선택
3. "Download" 버튼 클릭
4. 파일명을 `META.csv`로 변경
5. `public/data/yahoo_finance/` 디렉토리에 저장

#### TSLA (Tesla)
1. https://finance.yahoo.com/quote/TSLA/history 방문
2. 기간 선택: "MAX" 또는 "5Y" 선택
3. "Download" 버튼 클릭
4. 파일명을 `TSLA.csv`로 변경
5. `public/data/yahoo_finance/` 디렉토리에 저장

#### NVDA (NVIDIA)
1. https://finance.yahoo.com/quote/NVDA/history 방문
2. 기간 선택: "MAX" 또는 "5Y" 선택
3. "Download" 버튼 클릭
4. 파일명을 `NVDA.csv`로 변경
5. `public/data/yahoo_finance/` 디렉토리에 저장

### 3단계: 디렉토리 생성 (필요시)
```bash
mkdir -p public/data/yahoo_finance
```

### 4단계: CSV 파일 저장
다운로드한 CSV 파일들을 다음 위치에 저장:
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

### 5단계: 데이터 임포트
```bash
rails daily_prices:import
```

### 6단계: 데이터 확인
```bash
rails daily_prices:stats
```

## CSV 파일 형식 확인

Yahoo Finance CSV 파일은 다음과 같은 형식이어야 합니다:

```csv
Date,Open,High,Low,Close,Adj Close,Volume
2024-01-18,150.25,152.30,149.80,151.20,151.20,50000000
2024-01-17,149.50,150.80,148.90,150.25,150.25,48000000
...
```

**중요**: 첫 번째 컬럼이 `Date`, 다섯 번째 또는 여섯 번째 컬럼이 `Close` 또는 `Adj Close`여야 합니다.

## 문제 해결

### CSV 파일을 찾을 수 없다는 오류
- 파일명이 정확한지 확인 (대문자: `AAPL.csv`)
- 파일이 올바른 디렉토리에 있는지 확인 (`public/data/yahoo_finance/`)
- 파일 확장자가 `.csv`인지 확인

### 데이터가 임포트되지 않음
- CSV 파일 형식이 올바른지 확인
- `rails daily_prices:import` 실행 시 오류 메시지 확인
- CSV 파일의 첫 번째 줄이 헤더인지 확인
