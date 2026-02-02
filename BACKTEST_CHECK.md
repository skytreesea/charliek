# 백테스트 점검 체크리스트

## 현재 상태
- ✅ AAPL.csv 파일 존재 확인됨 (`public/data/yahoo_finance/AAPL.csv`)

## 점검 항목

### 1. 데이터 임포트 확인
```bash
rails daily_prices:import
```
- AAPL 데이터가 정상적으로 임포트되는지 확인
- 날짜 범위 확인

### 2. 데이터 상태 확인
```bash
rails daily_prices:check
```
또는
```bash
rails daily_prices:stats
```
- DailyPrice 테이블에 AAPL 데이터가 있는지 확인
- 날짜 범위 확인

### 3. 백테스트 작동 확인
- `/backtests` 페이지 접속
- AAPL만 선택 (1개 종목)
- 비중 100% 설정
- 데이터가 있는 날짜 범위로 시작일/종료일 설정
- "결과 보기" 클릭

## 예상 결과
- ✅ 1개 종목만 있어도 백테스트 작동 가능 (최소 1개, 최대 3개 지원)
- ✅ AAPL만 선택하고 비중 100%로 설정 가능
- ✅ 포트폴리오 가치 추이 차트 표시
- ✅ 일별 수익률 차트 표시
- ✅ 총 수익률, 최종 자산 가치, MDD 표시

## 주의사항
- 날짜 범위는 DailyPrice에 있는 데이터 범위 내에서만 선택 가능
- AAPL만 선택하면 비중은 100%로 자동 설정됨
- 다른 종목(MSFT, GOOGL 등)은 선택해도 데이터가 없으면 오류 발생
