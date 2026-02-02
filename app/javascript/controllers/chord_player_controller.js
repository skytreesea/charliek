import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    chords: Array,
    chordIndex: Number
  }

  connect() {
    // 플레이어가 없으면 초기화
    if (!window.chordPlayer) {
      // ChordPlayer는 전역으로 로드됨
      if (window.ChordPlayer) {
        window.chordPlayer = new window.ChordPlayer()
      }
    }
  }

  play() {
    // 단일 코드 재생 (사용하지 않음)
  }

  async playAll() {
    const button = this.element.querySelector('.play-all-button')
    const icon = button.querySelector('svg')
    
    console.log('playAll 호출됨');
    console.log('chordPlayer 존재:', !!window.chordPlayer);
    console.log('chordsValue:', this.chordsValue);
    
    if (!window.chordPlayer) {
      console.error('chordPlayer가 없습니다!');
      alert('오디오 플레이어를 초기화할 수 없습니다. 페이지를 새로고침해주세요.');
      return;
    }
    
    if (window.chordPlayer.isPlaying) {
      window.chordPlayer.stop()
      this.updateButtonState(button, icon, false)
      return
    }

    // 원본 코드 배열을 그대로 전달 (playProgression에서 2중 루프로 처리)
    // 예: ['C', 'G', 'Am', 'F'] -> 각 코드가 4번씩 연주됨 (총 16비트)
    const chords = this.chordsValue;
    
    console.log('원본 코드 배열:', chords);
    
    this.updateButtonState(button, icon, true)
    
    try {
      await window.chordPlayer.playProgression(chords, (beatCount, currentChord, chordIndex) => {
        if (beatCount !== null) {
          console.log(`비트 ${beatCount}: ${currentChord}`);
        } else {
          console.log('재생 완료');
          // 재생 완료
          this.updateButtonState(button, icon, false)
        }
      })
    } catch (error) {
      console.error('재생 오류:', error)
      this.updateButtonState(button, icon, false)
      alert('오디오 재생에 실패했습니다: ' + error.message)
    }
  }

  updateButtonState(button, icon, isPlaying) {
    if (isPlaying) {
      button.classList.remove('bg-green-500', 'hover:bg-green-600')
      button.classList.add('bg-red-500', 'hover:bg-red-600')
      icon.innerHTML = `
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
      `
    } else {
      button.classList.remove('bg-red-500', 'hover:bg-red-600')
      button.classList.add('bg-green-500', 'hover:bg-green-600')
      icon.innerHTML = `
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z" />
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      `
    }
  }
}
