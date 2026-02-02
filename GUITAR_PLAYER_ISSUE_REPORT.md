# 기타 플레이어 문제 분석 보고서

## 현재 상황

### 1. UI 구조
- **각 코드 옆에 개별 플레이 버튼** (64-78줄): 제거 필요
- **코드 악보 오른쪽 전체 재생 버튼** (20-34줄): `chord-player` 컨트롤러 사용 중
- 사용자 요구: 오른쪽 버튼만 남기고, 이 버튼을 누르면 기타 사운드 재생

### 2. 현재 구현 상태

#### `guitar_player_controller.js`의 문제점:
1. **단일 코드만 재생**: `play()` 메서드가 하나의 코드만 재생하도록 설계됨
2. **전체 코드 진행 미지원**: 여러 코드를 순차적으로 재생하는 기능 없음
3. **Tone.Transport 스케줄링 오류**: 
   - `Tone.Transport.schedule()`의 시간 포맷이 잘못됨
   - `"0:0", "0:1", "0:2", "0:3"` 형식은 Transport의 상대 시간이 아니라 절대 시간으로 해석됨
   - Transport가 이미 시작된 상태에서 스케줄을 추가하면 시간 계산이 꼬임

#### `chord_player_controller.js`의 현재 상태:
- `window.chordPlayer` (Web Audio API 기반) 사용
- 전체 코드 진행을 재생하는 `playAll()` 메서드 존재
- 각 코드를 4번씩 연주하는 로직 구현됨

## 핵심 문제점

### 문제 1: Tone.Transport 스케줄링 방식 오류
```javascript
// 현재 코드 (잘못된 방식)
beats.forEach((time) => {
  Tone.Transport.schedule((time) => {
    this.strumChord(this.chordValue, time)
  }, time)
})
```

**문제:**
- `Tone.Transport.schedule()`의 두 번째 인자는 Transport의 현재 위치 기준 상대 시간
- Transport가 이미 실행 중이면 `"0:0"`이 현재 위치가 되어버림
- 첫 번째 코드만 재생되고 이후 스케줄이 제대로 동작하지 않음

### 문제 2: 전체 코드 진행 재생 기능 부재
- `guitar_player_controller.js`는 단일 코드만 처리
- 여러 코드를 순차적으로 재생하는 `playAll()` 메서드 없음
- 각 코드를 한 마디에 4번 연주하는 로직 없음

### 문제 3: Transport 상태 관리 오류
- `Tone.Transport.cancel()` 후에도 Transport가 계속 실행 중일 수 있음
- 여러 번 클릭 시 스케줄이 중복으로 쌓임
- Transport를 완전히 정지하고 재시작하는 로직 필요

## 해결 방안

### 1. 전체 코드 진행 재생 메서드 추가
- `playAll()` 메서드를 `guitar_player_controller.js`에 추가
- 코드 배열을 받아서 각 코드를 순차적으로 재생
- 각 코드를 한 마디(4비트)에 4번 연주

### 2. Tone.Transport 스케줄링 수정
- Transport를 완전히 정지하고 재시작
- 절대 시간 기준으로 스케줄링 (Transport의 현재 시간 + 오프셋)
- 또는 `Tone.Transport.scheduleOnce()` 사용

### 3. 코드 진행 재생 로직
```javascript
// 의사코드
playAll() {
  // Transport 완전 정지 및 초기화
  Tone.Transport.stop()
  Tone.Transport.cancel()
  
  // 각 코드마다
  chords.forEach((chord, chordIndex) => {
    // 한 마디(4비트)에 4번 연주
    for (let beat = 0; beat < 4; beat++) {
      const time = `${chordIndex}:${beat}` // 마디:비트 형식
      Tone.Transport.scheduleOnce((time) => {
        this.strumChord(chordNotes, time)
      }, time)
    }
  })
  
  // Transport 시작
  Tone.Transport.start()
}
```

### 4. UI 수정
- 각 코드 옆 플레이 버튼 제거 (64-78줄)
- 오른쪽 전체 재생 버튼을 `guitar-player` 컨트롤러로 변경
- `data-guitar-player-chords-value`에 코드 배열 전달

## 수정 필요 파일

1. `app/views/mymuse/create.turbo_stream.erb`
   - 각 코드 옆 플레이 버튼 제거
   - 전체 재생 버튼을 `guitar-player` 컨트롤러로 변경

2. `app/javascript/controllers/guitar_player_controller.js`
   - `playAll()` 메서드 추가
   - 전체 코드 진행을 재생하는 로직 구현
   - Tone.Transport 스케줄링 방식 수정
   - 각 코드를 한 마디에 4번 연주하는 로직 추가

3. `app/helpers/application_helper.rb`
   - 코드 진행 전체를 음표 배열로 변환하는 헬퍼 메서드 추가 (선택사항)

## 예상 동작

1. 사용자가 오른쪽 플레이 버튼 클릭
2. `guitar-player#playAll()` 호출
3. 코드 배열을 순회하면서:
   - 각 코드를 한 마디(4비트)에 4번 연주
   - 각 연주마다 스트럼 효과 적용 (0.03초 간격)
4. 모든 코드 재생 완료 후 버튼 상태 복원
