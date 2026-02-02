# BacktestService 사용 가이드

## 개요
포트폴리오 백테스트를 수행하는 서비스 클래스입니다. M7 종목의 일별 종가 데이터를 기반으로 포트폴리오 성과를 분석합니다.

## 사용 방법

### 기본 사용 예시

```ruby
# 1. 단일 종목 백테스트
result = BacktestService.new(
  tickers_with_weights: [
    { ticker: 'AAPL', weight: 1.0 }
  ],
  start_date: '2020-01-01',
  end_date: '2024-12-31',
  exchange_rate: 1300.0  # 1달러 = 1300원
).call

# 2. 2개 종목 포트폴리오
result = BacktestService.new(
  tickers_with_weights: [
    { ticker: 'AAPL', weight: 0.6 },
    { ticker: 'MSFT', weight: 0.4 }
  ],
  start_date: Date.new(2020, 1, 1),
  end_date: Date.new(2024, 12, 31),
  exchange_rate: 1300.0
).call

# 3. 3개 종목 포트폴리오 (최대)
result = BacktestService.new(
  tickers_with_weights: [
    { ticker: 'AAPL', weight: 0.4 },
    { ticker: 'MSFT', weight: 0.35 },
    { ticker: 'GOOGL', weight: 0.25 }
  ],
  start_date: '2020-01-01',
  end_date: '2024-12-31',
  exchange_rate: 1300.0
).call
```

### 결과 확인

```ruby
if result[:error]
  puts "에러: #{result[:error]}"
else
  puts "총 수익률: #{result[:total_return]}%"
  puts "최종 자산 가치: #{result[:final_value_krw].to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}원"
  puts "최대 낙폭 (MDD): #{result[:max_drawdown]}%"
  
  # 일별 포트폴리오 가치 확인
  result[:portfolio_values].each do |pv|
    puts "#{pv[:date]}: #{pv[:portfolio_index]}"
  end
end
```

## 입력 파라미터

### tickers_with_weights (필수)
- 타입: Array of Hash
- 설명: 티커와 비중의 배열
- 제한: 최대 3개 종목
- 형식: `[{ticker: 'AAPL', weight: 0.5}, {ticker: 'MSFT', weight: 0.5}]`
- 비중의 합은 1.0이어야 함

### start_date (필수)
- 타입: Date 또는 String (YYYY-MM-DD 형식)
- 설명: 백테스트 시작일

### end_date (필수)
- 타입: Date 또는 String (YYYY-MM-DD 형식)
- 설명: 백테스트 종료일

### exchange_rate (선택)
- 타입: Float
- 기본값: 1.0
- 설명: 달러 대비 원화 환율 (1달러 = N원)

## 반환값

### 성공 시

```ruby
{
  total_return: 45.23,           # 총 수익률 (%)
  final_value_krw: 1452300.0,   # 최종 자산 가치 (원화)
  max_drawdown: 12.5,           # 최대 낙폭 (MDD, %)
  initial_value: 100.0,         # 시작 가치 (지수화 기준)
  final_value: 145.23,          # 최종 가치 (지수화 기준)
  portfolio_values: [            # 일별 포트폴리오 가치
    {
      date: Date.new(2020, 1, 1),
      portfolio_index: 100.0,
      indexed_prices: { 'AAPL' => 100.0, 'MSFT' => 100.0 }
    },
    # ...
  ]
}
```

### 실패 시

```ruby
{
  error: "에러 메시지"
}
```

## 계산 로직

### 지수화 (Indexing)
- 시작일의 각 종목 가격을 100으로 정규화
- 이후 날짜의 가격을 시작일 대비 비율로 계산
- 예: 시작일 AAPL $150 → 100, 이후 $165 → 110

### 포트폴리오 가치 계산
- 각 날짜별로: `포트폴리오 지수 = Σ(종목 지수 × 비중)`
- 예: AAPL 지수 110 (비중 0.6) + MSFT 지수 105 (비중 0.4) = 108

### 총 수익률
- `((최종 가치 - 시작 가치) / 시작 가치) × 100`

### 최종 자산 가치 (원화)
- 시작 자산 100만원 기준
- `100만원 × (최종 가치 / 시작 가치) × 환율`

### 최대 낙폭 (MDD)
- 각 시점에서 최고점 대비 하락률 계산
- 그 중 최대값이 MDD
- 예: 최고점 120에서 105로 하락 → MDD = ((120-105)/120) × 100 = 12.5%

## 에러 처리

서비스는 다음 경우에 에러를 반환합니다:

- 티커와 비중 배열이 비어있거나 형식이 잘못됨
- 종목이 3개를 초과함
- 비중의 합이 1.0이 아님
- 시작일이 종료일보다 늦음
- 시작일의 데이터가 일부 종목에 없음
- 환율이 0 이하

## 주의사항

1. **데이터 가용성**: 시작일의 데이터가 모든 종목에 있어야 합니다.
2. **거래일**: 주말/공휴일 데이터는 없을 수 있으므로, 가장 가까운 이전 거래일의 가격을 사용합니다.
3. **환율**: 환율은 고정값으로 가정합니다. 실제로는 일별 환율 변동을 고려해야 합니다.
4. **수수료/세금**: 실제 거래 비용은 고려하지 않습니다.
