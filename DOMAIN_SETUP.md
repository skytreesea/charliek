# charliek.kr 도메인 연결 가이드

## 1. Fly.io에 도메인 추가

터미널에서 다음 명령어를 실행하세요:

```bash
cd /home/kch/projects/charliek
fly certs add charliek.kr
```

이 명령어를 실행하면 Fly.io가 DNS 설정 정보를 제공합니다.

## 2. DNS 설정

도메인 등록 업체(예: 가비아, 후이즈, 네임서버 등)에서 다음 DNS 레코드를 추가하세요:

### 방법 1: A 레코드 사용 (권장)
```
타입: A
호스트: @ (또는 비워두기)
값: Fly.io에서 제공한 IP 주소
TTL: 3600 (또는 기본값)
```

### 방법 2: CNAME 사용
```
타입: CNAME
호스트: @ (또는 비워두기)
값: charlie-k.fly.dev
TTL: 3600 (또는 기본값)
```

**참고**: 일부 도메인 등록 업체는 루트 도메인(@)에 CNAME을 허용하지 않을 수 있습니다. 이 경우 A 레코드를 사용하세요.

## 3. SSL 인증서 발급 확인

DNS 설정이 완료되면 (보통 몇 분에서 몇 시간 소요), 다음 명령어로 인증서 상태를 확인하세요:

```bash
fly certs show charliek.kr
```

인증서가 발급되면 "Issued" 상태로 표시됩니다.

## 4. www 서브도메인 추가 (선택사항)

www.charliek.kr도 연결하려면:

```bash
fly certs add www.charliek.kr
```

그리고 DNS에 CNAME 레코드 추가:
```
타입: CNAME
호스트: www
값: charlie-k.fly.dev
TTL: 3600
```

## 5. 확인

DNS 전파가 완료되면 (보통 5분~24시간):
- https://charliek.kr 접속 테스트
- SSL 인증서가 자동으로 발급되었는지 확인

## 문제 해결

### DNS가 전파되지 않는 경우
- DNS 전파 확인 도구 사용: https://www.whatsmydns.net/
- 도메인 등록 업체의 DNS 설정이 올바른지 확인

### SSL 인증서가 발급되지 않는 경우
- DNS 설정이 올바른지 확인
- `fly certs check charliek.kr` 명령어로 상태 확인
- Fly.io 대시보드에서 인증서 상태 확인

### 도메인이 연결되지 않는 경우
- `fly status` 명령어로 앱 상태 확인
- `fly logs` 명령어로 로그 확인
