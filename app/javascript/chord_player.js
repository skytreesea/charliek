// Chord Player - 코드 재생 기능
// 어쿠스틱 기타 스타일로 업그레이드
// 정밀 스케줄링: audioContext.currentTime 기준으로 모든 오디오 이벤트 스케줄링

class ChordPlayer {
  constructor(options = {}) {
    this.bpm = options.bpm || 120;
    this.beatsPerMeasure = options.beatsPerMeasure || 1; // 기본값 1로 변경
    this.audioContext = null;
    this.isPlaying = false;
    this.scheduledOscillators = []; // 재생 중인 오실레이터 추적
    
    // 코드별 음정 정의 (C4 = Middle C)
    this.chordNotes = {
      'C': ['C4', 'E4', 'G4'],
      'Dm': ['D4', 'F4', 'A4'],
      'Em': ['E4', 'G4', 'B4'],
      'F': ['F4', 'A4', 'C5'],
      'G': ['G4', 'B4', 'D5'],
      'Am': ['A4', 'C5', 'E5'],
      'Em7': ['E4', 'G4', 'B4', 'D5'],
      'Fmaj7': ['F4', 'A4', 'C5', 'E5'],
      'E': ['E4', 'G#4', 'B4']
    };
    
    // 음정 주파수 매핑
    this.noteFrequencies = {
      'C4': 261.63, 'C#4': 277.18, 'D4': 293.66, 'D#4': 311.13,
      'E4': 329.63, 'F4': 349.23, 'F#4': 369.99, 'G4': 392.00,
      'G#4': 415.30, 'A4': 440.00, 'A#4': 466.16, 'B4': 493.88,
      'C5': 523.25, 'C#5': 554.37, 'D5': 587.33, 'D#5': 622.25,
      'E5': 659.25, 'F5': 698.46, 'F#5': 739.99, 'G5': 783.99
    };
  }

  // AudioContext 초기화
  async initAudioContext() {
    if (!this.audioContext) {
      this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
      console.log('AudioContext 생성:', this.audioContext.state);
    }
    
    // AudioContext가 suspended 상태면 resume
    if (this.audioContext.state === 'suspended') {
      console.log('AudioContext 재개 중...');
      await this.audioContext.resume();
      console.log('AudioContext 상태:', this.audioContext.state);
    }
    
    return this.audioContext;
  }

  // 음표 재생 (어쿠스틱 기타 스타일)
  playNote(frequency, startTime, duration) {
    if (!this.audioContext || this.audioContext.state === 'closed') {
      console.warn('AudioContext가 사용 불가능합니다:', this.audioContext?.state);
      return null;
    }
    
    try {
      const oscillator = this.audioContext.createOscillator();
      const gainNode = this.audioContext.createGain();
      
      // 하이패스 필터 (맑은 소리)
      const highpassFilter = this.audioContext.createBiquadFilter();
      highpassFilter.type = 'highpass';
      highpassFilter.frequency.value = 200; // 200Hz 이하 차단
      highpassFilter.Q.value = 1;

      oscillator.connect(highpassFilter);
      highpassFilter.connect(gainNode);
      gainNode.connect(this.audioContext.destination);

      oscillator.frequency.value = frequency;
      oscillator.type = 'triangle'; // 기타 같은 음색

      // 기타 엔벨로프 (ADSR) - 기타 음색 강화
      // Attack: 0.01초 (순식간에 소리가 커짐)
      gainNode.gain.setValueAtTime(0, startTime);
      gainNode.gain.linearRampToValueAtTime(0.4, startTime + 0.01);
      
      // Decay/Sustain: duration 동안 서서히 지수 함수 형태로 소리가 0.01까지 줄어들게
      // exponentialRampToValueAtTime 사용하여 자연스러운 감쇠
      gainNode.gain.exponentialRampToValueAtTime(0.01, startTime + duration);

      // 메모리 관리: 오실레이터가 확실히 정지되도록 명시
      oscillator.start(startTime);
      oscillator.stop(startTime + duration);

      return { oscillator, gainNode };
    } catch (error) {
      console.error('음표 재생 오류:', error);
      return null;
    }
  }

  // 코드 재생 (기타 스트럼 효과: 각 음표를 0.03초 시차로 순차 재생)
  playChord(chordName, chordStartTime) {
    if (!this.audioContext || this.audioContext.state === 'closed') {
      console.warn('AudioContext가 사용 불가능합니다:', this.audioContext?.state);
      return;
    }
    
    const notes = this.chordNotes[chordName];
    if (!notes) {
      console.warn(`Unknown chord: ${chordName}`);
      return;
    }

    const beatDuration = 60 / this.bpm; // 1비트의 길이 (초)
    // 각 음표는 beatDuration 동안 재생되지만, 엔벨로프는 최대 1.5초까지
    // beatDuration이 1.5초보다 작으면 beatDuration 사용, 크면 1.5초 사용
    const noteDuration = Math.min(beatDuration, 1.5); // 최대 1.5초
    const strumDelay = 0.03; // 스트럼 시차 (0.03초) - 기타를 긁는 소리

    // 각 음표를 순차적으로 재생 (기타를 위에서 아래로 긁는 느낌)
    notes.forEach((note, index) => {
      const noteStartTime = chordStartTime + (index * strumDelay);
      const noteResult = this.playNote(
        this.noteFrequencies[note],
        noteStartTime,
        noteDuration
      );
      
      if (noteResult) {
        this.scheduledOscillators.push(noteResult);
      }
    });
  }

  // 코드 진행 재생 (4/4박자 마디 시스템: 각 코드를 beatsPerMeasure번씩 연주)
  async playProgression(chords, onBeatCallback = null) {
    if (this.isPlaying) {
      this.stop();
    }
    
    // AudioContext 초기화 및 활성화 (사용자 인터랙션 후)
    await this.initAudioContext();
    
    if (!this.audioContext || this.audioContext.state === 'closed') {
      console.error('AudioContext를 초기화할 수 없습니다. 상태:', this.audioContext?.state);
      if (onBeatCallback) {
        onBeatCallback(null, null, null);
      }
      return;
    }

    this.isPlaying = true;
    this.scheduledOscillators = []; // 오실레이터 배열 초기화
    const beatDuration = 60 / this.bpm; // 1비트의 길이 (초)
    
    // 시작 시간 기록 (절대 시간 기준)
    const now = this.audioContext.currentTime;
    
    console.log('=== 재생 시작 (4/4박자 마디 시스템) ===');
    console.log('원본 코드 배열:', chords);
    console.log('BPM:', this.bpm);
    console.log('한 마디당 연주 횟수:', this.beatsPerMeasure);
    console.log('비트 길이:', beatDuration.toFixed(3), '초');
    console.log('시작 시간:', now.toFixed(3), '초');
    console.log('총 마디 수:', chords.length);
    console.log('총 비트 수:', chords.length * this.beatsPerMeasure);

    // 2중 루프 스케줄링: 각 코드마다 한 마디(4비트)에 beatsPerMeasure번씩 연주
    // 비트 간격 = 4 / beatsPerMeasure
    // 예: 1번이면 4비트 간격, 2번이면 2비트 간격, 4번이면 1비트 간격
    const beatInterval = 4 / this.beatsPerMeasure
    
    chords.forEach((chord, measureIndex) => {
      // 각 마디의 beatsPerMeasure번을 순회
      for (let beatIndex = 0; beatIndex < this.beatsPerMeasure; beatIndex++) {
        // 각 연주의 비트 위치 계산: 0, beatInterval, beatInterval*2, ...
        const beatPosition = beatIndex * beatInterval
        // 절대 시간 동기화: 한 마디는 4비트이므로 (마디인덱스 * 4 + 비트위치) * beatDuration
        const absoluteTime = now + ((measureIndex * 4 + beatPosition) * beatDuration);
        const globalBeatIndex = measureIndex * 4 + beatPosition;
        
        // 디버깅: 각 비트 예약 정보 출력
        console.log(`[비트 예약] 마디 ${measureIndex + 1}, 비트 위치 ${beatPosition.toFixed(1)} (${beatIndex + 1}/${this.beatsPerMeasure}번 연주) | 코드: ${chord} | 절대 시간: ${absoluteTime.toFixed(3)}s | 전역 비트 인덱스: ${globalBeatIndex}`);
        
        // 코드 재생 스케줄링 (정확한 시간에)
        this.playChord(chord, absoluteTime);
        
        // 콜백 처리 (requestAnimationFrame 사용)
        if (onBeatCallback) {
          const callbackTime = absoluteTime;
          const checkCallback = () => {
            const currentTime = this.audioContext.currentTime;
            if (currentTime >= callbackTime - 0.01 && currentTime < callbackTime + beatDuration) {
              if (this.isPlaying) {
                onBeatCallback(globalBeatIndex, chord, measureIndex);
              }
            } else if (currentTime < callbackTime) {
              requestAnimationFrame(checkCallback);
            }
          };
          requestAnimationFrame(checkCallback);
        }
      }
    });

    // 재생 완료 처리 (마지막 코드 재생 후 1.5초 뒤)
    // 한 마디는 항상 4비트이므로 총 비트 수 = 마디 수 * 4
    const totalBeats = chords.length * 4;
    const totalDuration = totalBeats * beatDuration;
    const finishTime = now + totalDuration + 1.5;
    
    console.log(`총 재생 시간: ${totalDuration.toFixed(3)}초 (${totalBeats}비트)`);
    console.log(`예상 완료 시간: ${finishTime.toFixed(3)}초`);
    
    const checkFinish = () => {
      const currentTime = this.audioContext.currentTime;
      if (currentTime >= finishTime) {
        if (this.isPlaying) {
          this.isPlaying = false;
          if (onBeatCallback) {
            onBeatCallback(null, null, null);
          }
          console.log('=== 재생 완료 ===');
        }
      } else {
        requestAnimationFrame(checkFinish);
      }
    };
    requestAnimationFrame(checkFinish);
  }

  // 재생 중지
  stop() {
    this.isPlaying = false;
    
    // 모든 오실레이터 중지
    this.scheduledOscillators.forEach(({ oscillator, gainNode }) => {
      try {
        gainNode.gain.cancelScheduledValues(this.audioContext.currentTime);
        gainNode.gain.setValueAtTime(0, this.audioContext.currentTime);
        oscillator.stop(this.audioContext.currentTime);
      } catch (error) {
        // 이미 중지된 경우 무시
      }
    });
    
    this.scheduledOscillators = [];
  }

  // 간단한 테스트 재생 (디버깅용)
  async testPlay() {
    try {
      await this.initAudioContext();
      console.log('테스트 재생 시작');
      console.log('AudioContext 상태:', this.audioContext?.state);
      
      if (!this.audioContext || this.audioContext.state === 'closed') {
        console.error('AudioContext가 사용 불가능합니다');
        return;
      }
      
      const now = this.audioContext.currentTime;
      
      // C 코드 재생 테스트
      this.playChord('C', now);
      console.log('C 코드 재생 완료');
    } catch (error) {
      console.error('테스트 재생 오류:', error);
    }
  }

  // BPM 설정
  setBPM(bpm) {
    this.bpm = bpm;
  }

  // 한 마디당 연주 횟수 설정
  setBeatsPerMeasure(beats) {
    this.beatsPerMeasure = beats;
    console.log('한 마디당 연주 횟수 설정:', beats);
  }
}

// 전역으로 export
window.ChordPlayer = ChordPlayer;

// 전역 인스턴스 생성
window.chordPlayer = new ChordPlayer();
