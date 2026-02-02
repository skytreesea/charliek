# 백테스트 데이터 임포트 문제 해결 가이드

## 문제: "데이터를 찾을 수 없습니다" 오류

### 원인 확인

1. **마이그레이션 실행 확인**
   ```bash
   rails db:migrate
   ```
   DailyPrice 테이블이 생성되었는지 확인합니다.

2. **CSV 파일 확인**
   - 파일 위치: `public/data/yahoo_finance/AAPL.csv`
   - 파일명이 정확한지 확인 (대문자 `AAPL.csv`)
   - 파일이 비어있지 않은지 확인

3. **CSV 파일 형식 확인**
   Yahoo Finance CSV 파일은 다음과 같은 형식이어야 합니다:
   ```csv
   Date,Open,High,Low,Close,Adj Close,Volume
   2024-01-18,150.25,152.30,149.80,151.20,151.20,50000000
   ```
   - 첫 번째 컬럼: `Date`
   - 다섯 번째 또는 여섯 번째 컬럼: `Close` 또는 `Adj Close`

### 해결 방법

**1단계: 마이그레이션 실행**
```bash
rails db:migrate
```

**2단계: 데이터 임포트 실행**
```bash
rails daily_prices:import
```

**3단계: 임포트 결과 확인**
- 오류 메시지가 있는지 확인
- "CSV 파일 첫 3줄" 출력 확인
- "첫 번째 행 샘플" 출력 확인
- "Imported", "Skipped", "Errors" 개수 확인

**4단계: 데이터 확인**
```bash
rails daily_prices:stats
```
또는
```bash
rails daily_prices:check
```

### 일반적인 문제

1. **CSV 파일 인코딩 문제**
   - 파일이 UTF-8 인코딩인지 확인
   - BOM이 있는 경우 자동으로 제거됨

2. **CSV 헤더 형식 문제**
   - Yahoo Finance에서 다운로드한 원본 파일 사용
   - Excel에서 저장한 경우 형식이 변경될 수 있음

3. **날짜 형식 문제**
   - 날짜가 `YYYY-MM-DD` 형식인지 확인
   - 다른 형식도 자동 파싱 시도

4. **가격 데이터 문제**
   - 가격이 숫자 형식인지 확인
   - 빈 값이나 잘못된 값은 자동으로 건너뜀

### 디버깅 팁

임포트 중 다음 정보가 출력됩니다:
- CSV 파일의 첫 3줄
- 첫 번째 행의 Date와 Adj Close 값
- CSV 헤더 정보
- 임포트/스킵/오류 개수

이 정보를 확인하여 문제를 진단할 수 있습니다.
