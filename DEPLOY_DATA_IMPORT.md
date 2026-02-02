# 배포 후 데이터 임포트 가이드

## 서버에서 해야 할 작업

### 1. CSV 파일 업로드

Fly.io 서버에 CSV 파일을 업로드해야 합니다. 두 가지 방법이 있습니다:

#### 방법 A: fly ssh sftp 사용 (권장)

```bash
# 로컬에서 실행
fly ssh sftp shell

# SFTP 세션에서
cd /rails/public/data/yahoo_finance
put /로컬경로/AAPL.csv
put /로컬경로/msft\ -\ 시트1.csv
put /로컬경로/m7\ -\ amzn.csv
put /로컬경로/m7\ -\ googl.csv
put /로컬경로/m7\ -\ meta.csv
put /로컬경로/nvda.csv
put /로컬경로/tsla.csv
exit
```

#### 방법 B: fly ssh console로 직접 업로드

```bash
# 로컬에서 CSV 파일들을 압축
tar -czf csv_files.tar.gz public/data/yahoo_finance/*.csv

# Fly.io에 파일 복사 (flyctl이 설치되어 있어야 함)
fly ssh console -C "mkdir -p /rails/public/data/yahoo_finance"

# 또는 fly ssh console로 접속 후 수동으로 파일 생성
fly ssh console
```

### 2. 데이터베이스 마이그레이션 확인

```bash
# 방법 1: bash -c 사용 (권장)
fly ssh console -C "bash -c 'RAILS_ENV=production bin/rails db:migrate'"

# 방법 2: 직접 접속
fly ssh console
# 콘솔에서
RAILS_ENV=production bin/rails db:migrate
exit
```

### 3. CSV 데이터 임포트

```bash
# 방법 1: bash -c 사용 (권장)
fly ssh console -C "bash -c 'RAILS_ENV=production bin/rails daily_prices:import'"

# 방법 2: 직접 접속
fly ssh console
# 콘솔에서
RAILS_ENV=production bin/rails daily_prices:import
exit
```

### 4. 데이터 확인

```bash
# 방법 1: bash -c 사용 (권장)
fly ssh console -C "bash -c 'RAILS_ENV=production bin/rails daily_prices:stats'"

# 방법 2: 직접 접속
fly ssh console
# 콘솔에서
RAILS_ENV=production bin/rails daily_prices:stats
exit
```

## 전체 작업 순서 (한 번에 실행)

```bash
# 1. CSV 파일 업로드 (SFTP 사용)
fly ssh sftp shell
# SFTP 세션에서 파일 업로드 후 exit

# 2. 데이터베이스 마이그레이션
fly ssh console -C "bash -c 'RAILS_ENV=production bin/rails db:migrate'"

# 3. CSV 데이터 임포트
fly ssh console -C "bash -c 'RAILS_ENV=production bin/rails daily_prices:import'"

# 4. 데이터 확인
fly ssh console -C "bash -c 'RAILS_ENV=production bin/rails daily_prices:stats'"
```

## 문제 해결

### CSV 파일이 없다는 오류가 나는 경우

```bash
# 디렉토리 확인
fly ssh console -C "ls -la /rails/public/data/yahoo_finance/"

# 디렉토리 생성 (없는 경우)
fly ssh console -C "mkdir -p /rails/public/data/yahoo_finance"
```

### 데이터베이스 연결 오류

```bash
# 데이터베이스 상태 확인
fly ssh console -C "bash -c 'RAILS_ENV=production bin/rails db:version'"

# 데이터베이스 재생성 (주의: 기존 데이터 삭제됨)
fly ssh console -C "bash -c 'RAILS_ENV=production bin/rails db:reset'"
```

### 권한 문제

```bash
# 파일 권한 확인 및 수정
fly ssh console -C "chmod -R 755 /rails/public/data"
```

## 자동화 스크립트 (선택사항)

로컬에서 실행할 수 있는 스크립트를 만들 수 있습니다:

```bash
#!/bin/bash
# deploy_data.sh

echo "📤 CSV 파일 업로드 중..."
# SFTP를 통한 파일 업로드 (수동으로 해야 함)

echo "🔄 데이터베이스 마이그레이션 중..."
fly ssh console -C "bash -c 'RAILS_ENV=production bin/rails db:migrate'"

echo "📊 데이터 임포트 중..."
fly ssh console -C "bash -c 'RAILS_ENV=production bin/rails daily_prices:import'"

echo "✅ 데이터 확인 중..."
fly ssh console -C "bash -c 'RAILS_ENV=production bin/rails daily_prices:stats'"

echo "✨ 완료!"
```

## 참고사항

- CSV 파일은 `/rails/public/data/yahoo_finance/` 경로에 있어야 합니다
- Fly.io의 볼륨 마운트(`/data`)는 데이터베이스용이므로 CSV 파일은 애플리케이션 디렉토리에 저장됩니다
- 배포 시 CSV 파일이 포함되도록 하려면 Dockerfile이나 배포 설정을 수정해야 할 수 있습니다
- 영구 저장이 필요하면 Fly.io 볼륨을 추가로 마운트하거나 외부 스토리지(S3 등)를 사용하는 것을 고려하세요
