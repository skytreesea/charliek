import { Controller } from "@hotwired/stimulus"
import * as Tone from "tone"

// 1. 코드와 노트를 매핑하는 사전(Dictionary)을 만듭니다.
const CHORD_MAP = {
  "C": "C3",
  "G": "G3",
  "Am": "A3",
  "F": "F3",
  "E": "E3",
  "Dm": "D3",
  "Em": "E4", // E와 겹치지 않게 옥타브 조절
  "D": "D4",
  "Em7": "E4", // Em7 코드가 없으면 Em 사용
  "Fmaj7": "F3" // Fmaj7 코드가 없으면 F 사용
}

export default class extends Controller {
  static values = {
    chord: Array,
    chords: Array
  }

  static targets = ["button", "bpmSlider", "bpmDisplay", "beatsPerMeasureSelect", "repeatCountSelect"]

  connect() {
    console.log("[GuitarPlayer] 컨트롤러 연결됨")
    
    // 1. 모든 가능성을 열어두고 Tone 객체를 찾습니다.
    let toneInstance = null
    if (Tone && Tone.Sampler) {
      toneInstance = Tone // 바로 들어있는 경우
    } else if (Tone && Tone.default && Tone.default.Sampler) {
      toneInstance = Tone.default // default 안에 들어있는 경우
    } else if (window.Tone && window.Tone.Sampler) {
      toneInstance = window.Tone // 전역 객체에 붙은 경우
    }

    this.tone = toneInstance

    // 2. 도구 확인 로그 (여기서 true가 나와야 합니다)
    console.log("[GuitarPlayer] 도구 최종 확인:", {
      Sampler: !!(this.tone && this.tone.Sampler),
      start: !!(this.tone && this.tone.start),
      Transport: !!(this.tone && this.tone.Transport),
      loaded: !!(this.tone && this.tone.loaded),
      context: !!(this.tone && this.tone.context)
    })

    if (!this.tone) {
      console.error("[GuitarPlayer] Tone.js 라이브러리를 찾을 수 없습니다. import를 확인하세요.")
      console.log("[GuitarPlayer] Tone 객체:", Tone)
      console.log("[GuitarPlayer] window.Tone:", window.Tone)
      return
    }

    this.isPlaying = false
    this.samplerLoaded = false
    this.bpm = 120 // 기본 BPM
    this.beatsPerMeasure = 1 // 기본값: 한 마디당 1번 연주
    this.repeatCount = 1 // 기본값: 반복 1회
    
    // 모바일에서 오디오 컨텍스트를 미리 준비 (선택사항)
    // 실제 재생은 사용자 인터랙션 후에만 가능
    this.initSampler()
    
    // BPM 초기화
    if (this.hasBpmSliderTarget) {
      this.updateBpm()
    }
    
    // 한 마디당 연주 횟수 초기화
    if (this.hasBeatsPerMeasureSelectTarget) {
      this.updateBeatsPerMeasure()
    }
    
    // 반복 횟수 초기화
    if (this.hasRepeatCountSelectTarget) {
      this.updateRepeatCount()
    }
  }
  
  updateBpm() {
    if (this.hasBpmSliderTarget) {
      const slider = this.bpmSliderTarget
      let bpm = parseInt(slider.value, 10)
      
      // 60-168 범위 제한
      bpm = Math.max(60, Math.min(168, bpm))
      slider.value = bpm
      this.bpm = bpm
      
      // BPM 표시 업데이트
      if (this.hasBpmDisplayTarget) {
        this.bpmDisplayTarget.textContent = bpm
      }
      
      // Transport BPM 설정
      if (this.tone && this.tone.Transport) {
        this.tone.Transport.bpm.value = bpm
        console.log(`[GuitarPlayer] BPM 변경: ${bpm}`)
      }
    }
  }

  updateBeatsPerMeasure() {
    if (this.hasBeatsPerMeasureSelectTarget) {
      const select = this.beatsPerMeasureSelectTarget
      const beats = parseInt(select.value, 10)
      
      // 1-4 범위 제한
      const validBeats = Math.max(1, Math.min(4, beats))
      if (validBeats !== beats) {
        select.value = validBeats
      }
      
      this.beatsPerMeasure = validBeats
      console.log(`[GuitarPlayer] 한 마디당 연주 횟수 변경: ${validBeats}`)
    }
  }

  updateRepeatCount() {
    if (this.hasRepeatCountSelectTarget) {
      const select = this.repeatCountSelectTarget
      const count = parseInt(select.value, 10)
      
      // 1-4 범위 제한
      const validCount = Math.max(1, Math.min(4, count))
      if (validCount !== count) {
        select.value = validCount
      }
      
      this.repeatCount = validCount
      console.log(`[GuitarPlayer] 반복 횟수 변경: ${validCount} (select.value: ${select.value})`)
    } else {
      // 타겟이 없으면 기본값 유지
      this.repeatCount = this.repeatCount || 1
      console.log(`[GuitarPlayer] 반복 횟수 타겟 없음, 기본값 사용: ${this.repeatCount}`)
    }
  }

  disconnect() {
    console.log("[GuitarPlayer] 컨트롤러 연결 해제됨")
    // [중요] 샘플러가 생성되었을 때만 stop을 호출하도록 방어
    if (this.sampler) {
      try {
        this.sampler.dispose()
      } catch (error) {
        console.warn("[GuitarPlayer] 샘플러 dispose 오류:", error)
      }
    }
    if (this.tone && this.tone.Transport) {
      try {
        this.tone.Transport.stop()
        this.tone.Transport.cancel()
      } catch (error) {
        console.warn("[GuitarPlayer] Transport 정지 오류:", error)
      }
    }
    this.isPlaying = false
    this.updateButtonState(false)
  }

  initSampler() {
    try {
      // 추출한 this.tone에서 Sampler를 가져옵니다.
      if (!this.tone.Sampler) {
        throw new Error("Tone.Sampler를 찾을 수 없습니다.")
      }

      // urls의 키를 CHORD_MAP에 정의된 '노트 이름'으로 바꿉니다.
      // E.wav와 D.wav가 없으므로 Em.wav와 Dm.wav를 대체로 사용
      this.sampler = new this.tone.Sampler({
        urls: {
          "C3": "C.wav",
          "G3": "G.wav",
          "A3": "Am.wav",
          "F3": "F.wav",
          "E3": "Em.wav", // E.wav가 없으므로 Em.wav 사용
          "D3": "Dm.wav",
          "E4": "Em.wav",
          "D4": "Dm.wav" // D.wav가 없으므로 Dm.wav 사용
        },
        baseUrl: "/audio/guitar/",
        release: 1,
        onload: () => {
          this.samplerLoaded = true
          console.log("[GuitarPlayer] 스튜디오 원 샘플 로딩 완료!")
        },
        onerror: (error) => {
          console.error("[GuitarPlayer] 샘플 로드 오류:", error)
        }
      }).toDestination()
      
      console.log("[GuitarPlayer] 샘플러 초기화 완료")
    } catch (e) {
      console.error("[GuitarPlayer] 샘플러 생성 실패:", e.message)
    }
  }

  async play() {
    console.log("[GuitarPlayer] play() 메서드 호출됨")
    console.warn("[GuitarPlayer] play() 메서드는 단일 코드 재생용입니다. playAll()을 사용하세요.")
  }

  async playAll(event) {
    console.log("[GuitarPlayer] playAll() 메서드 호출됨")
    
    // 터치/클릭 이벤트 중복 방지
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    // 모바일: 사용자 인터랙션 직후 즉시 오디오 컨텍스트 활성화 (가장 중요!)
    // 이 부분이 사용자 인터랙션 핸들러 내에 있어야 모바일에서 작동함
    try {
      // Tone.js start를 먼저 호출하여 오디오 컨텍스트 활성화
      if (this.tone && this.tone.start && typeof this.tone.start === 'function') {
        await this.tone.start()
        console.log("[GuitarPlayer] Tone.js start() 완료 (사용자 인터랙션 직후)")
      }
    } catch (error) {
      console.warn("[GuitarPlayer] 초기 Tone.js start() 실패:", error.message)
    }

    // 이미 재생 중이면 중지하고 처음부터 다시 시작
    if (this.isPlaying) {
      console.log("[GuitarPlayer] 이미 재생 중이므로 중지 후 재시작")
      this.stop()
      await new Promise(resolve => setTimeout(resolve, 100))
    }

    // 코드 배열이 없으면 리턴
    if (!this.chordsValue || this.chordsValue.length === 0) {
      console.warn("[GuitarPlayer] 코드 배열이 설정되지 않았습니다")
      return
    }

    try {
      // 모바일 호환 오디오 컨텍스트 활성화
      // Tone.js의 context를 직접 확인하고 활성화
      let audioContext = null
      
      // Tone.js context 찾기 (여러 방법 시도)
      if (this.tone.context) {
        audioContext = this.tone.context
      } else if (this.tone.getContext && typeof this.tone.getContext === 'function') {
        audioContext = this.tone.getContext()
      } else if (this.tone.Context) {
        if (this.tone.Context.getContext && typeof this.tone.Context.getContext === 'function') {
          audioContext = this.tone.Context.getContext()
        } else if (this.tone.Context.context) {
          audioContext = this.tone.Context.context
        }
      } else if (window.Tone) {
        if (window.Tone.context) {
          audioContext = window.Tone.context
        } else if (window.Tone.getContext && typeof window.Tone.getContext === 'function') {
          audioContext = window.Tone.getContext()
        } else if (window.Tone.Context && window.Tone.Context.getContext) {
          audioContext = window.Tone.Context.getContext()
        }
      }
      
      // Sampler에서 직접 context 가져오기 시도
      if (!audioContext && this.sampler && this.sampler.context) {
        audioContext = this.sampler.context
      }
      
      // 오디오 컨텍스트 활성화 (모바일에서 중요)
      if (audioContext) {
        console.log("[GuitarPlayer] 오디오 컨텍스트 찾음:", audioContext.state)
        
        // suspended 상태면 resume (최대 5번 시도, 모바일에서 더 많은 시도 필요)
        let resumeAttempts = 0
        const maxResumeAttempts = 5
        while (audioContext.state === 'suspended' && resumeAttempts < maxResumeAttempts) {
          console.log(`[GuitarPlayer] 오디오 컨텍스트 재개 시도 ${resumeAttempts + 1}/${maxResumeAttempts}...`)
          try {
            const resumePromise = audioContext.resume()
            await resumePromise
            // 상태 확인을 위해 짧은 대기
            await new Promise(resolve => setTimeout(resolve, 50))
            console.log("[GuitarPlayer] 오디오 컨텍스트 상태 (재개 후):", audioContext.state)
          } catch (error) {
            console.warn("[GuitarPlayer] 오디오 컨텍스트 resume 실패:", error)
          }
          resumeAttempts++
          
          // 짧은 대기 후 다시 확인
          if (audioContext.state === 'suspended' && resumeAttempts < maxResumeAttempts) {
            await new Promise(resolve => setTimeout(resolve, 150))
          }
        }
      } else {
        // audioContext를 찾지 못한 경우, Tone.js의 start 메서드로 시도
        console.warn("[GuitarPlayer] 오디오 컨텍스트를 직접 찾지 못했습니다. Tone.js start() 시도...")
      }
      
      // Tone.js의 start 메서드 재호출 (이미 위에서 호출했지만 이중 보장)
      if (this.tone.start && typeof this.tone.start === 'function') {
        try {
          await this.tone.start()
          console.log("[GuitarPlayer] Tone.js start() 재호출 완료")
          // start() 후 context 다시 확인
          if (!audioContext && this.tone.context) {
            audioContext = this.tone.context
            console.log("[GuitarPlayer] start() 후 context 찾음:", audioContext.state)
            if (audioContext.state === 'suspended') {
              await audioContext.resume()
            }
          }
        } catch (error) {
          console.warn("[GuitarPlayer] Tone.js start() 재호출 실패:", error.message)
        }
      }
      
      // 최종 확인 및 경고
      if (audioContext) {
        if (audioContext.state === 'running') {
          console.log("[GuitarPlayer] ✅ 오디오 컨텍스트 활성화 완료")
        } else {
          console.warn(`[GuitarPlayer] ⚠️ 오디오 컨텍스트 상태: ${audioContext.state}`)
          // suspended 상태면 한 번 더 시도
          if (audioContext.state === 'suspended') {
            console.warn("[GuitarPlayer] 마지막 시도: resume() 호출")
            try {
              await audioContext.resume()
              await new Promise(resolve => setTimeout(resolve, 100))
              console.log("[GuitarPlayer] 최종 상태:", audioContext.state)
            } catch (error) {
              console.error("[GuitarPlayer] 최종 resume 실패:", error)
            }
          }
        }
      } else {
        console.warn("[GuitarPlayer] ⚠️ 오디오 컨텍스트를 찾을 수 없습니다")
      }

      // 샘플러가 없으면 초기화
      if (!this.sampler) {
        console.warn("[GuitarPlayer] 샘플러가 없습니다. 재초기화 시도...")
        this.initSampler()
        // 샘플러 초기화 후 짧은 대기
        await new Promise(resolve => setTimeout(resolve, 100))
      }
      
      // 샘플 로딩 대기 (모바일 호환)
      if (!this.samplerLoaded) {
        console.log("[GuitarPlayer] 샘플 로딩 대기 중...")
        
        // Tone.js의 loaded 메서드가 있으면 사용
        if (this.tone.loaded && typeof this.tone.loaded === 'function') {
          try {
            await this.tone.loaded()
            console.log("[GuitarPlayer] Tone.js loaded() 완료")
          } catch (error) {
            console.warn("[GuitarPlayer] Tone.js loaded() 실패:", error)
          }
        }
        
        // 샘플러의 로딩 상태 확인 (최대 5초 대기, 모바일에서 더 오래 기다림)
        let waitCount = 0
        const maxWait = 50 // 5초 (100ms * 50)
        while (!this.samplerLoaded && waitCount < maxWait) {
          await new Promise(resolve => setTimeout(resolve, 100))
          waitCount++
          
          // 중간에 샘플러가 로드되었는지 확인
          if (this.sampler && this.sampler.loaded !== false) {
            // 샘플러가 준비된 것으로 간주
            this.samplerLoaded = true
            break
          }
        }
        
        if (this.samplerLoaded) {
          console.log("[GuitarPlayer] 샘플 로딩 완료")
        } else {
          console.warn("[GuitarPlayer] 샘플 로딩 타임아웃, 계속 진행합니다")
          // 타임아웃이어도 계속 진행 (샘플러가 있을 수 있음)
          this.samplerLoaded = true
        }
      }
      
      // 샘플러가 준비되었는지 최종 확인
      if (this.sampler) {
        // 샘플러가 있으면 로드된 것으로 간주
        this.samplerLoaded = true
      }

      if (!this.sampler) {
        throw new Error("샘플러가 없습니다.")
      }

      console.log("[GuitarPlayer] 재생 시작:", this.chordsValue)

      // 재생 스케줄링
      const transport = this.tone.Transport
      if (!transport) {
        throw new Error("Transport를 찾을 수 없습니다.")
      }

      // Transport 완전 정지 및 초기화 (이전 스케줄 제거)
      transport.stop()
      transport.cancel()
      
      // 모든 스케줄 명시적으로 제거 (중복 재생 방지)
      if (transport.clear && typeof transport.clear === 'function') {
        transport.clear()
      }
      
      transport.position = 0
      
      // Transport가 완전히 정지될 때까지 짧은 대기 (중복 재생 방지)
      await new Promise(resolve => setTimeout(resolve, 50))
      
      // BPM 설정
      transport.bpm.value = this.bpm
      console.log(`[GuitarPlayer] BPM 설정: ${this.bpm}`)

      this.isPlaying = true
      this.updateButtonState(true)

      // 반복 횟수 확인 및 업데이트 (재생 전에 최신 값으로 업데이트)
      if (this.hasRepeatCountSelectTarget) {
        this.updateRepeatCount()
      }
      
      // 각 코드마다 한 마디(4비트)에 beatsPerMeasure번 연주
      // 비트 간격 = 4 / beatsPerMeasure
      // 예: 1번이면 4비트 간격(0, 4, 8...), 2번이면 2비트 간격(0, 2, 4...), 4번이면 1비트 간격(0, 1, 2, 3...)
      const beatInterval = 4 / this.beatsPerMeasure
      const originalChordsLength = this.chordsValue.length
      
      console.log(`[GuitarPlayer] 반복 횟수: ${this.repeatCount}, 원본 코드 길이: ${originalChordsLength}, 총 마디 수: ${originalChordsLength * this.repeatCount}`)
      
      // 반복 횟수에 따라 전체 코드 진행을 반복 연주
      for (let repeatIndex = 0; repeatIndex < this.repeatCount; repeatIndex++) {
        this.chordsValue.forEach((chordName, mIndex) => {
          // 반복을 고려한 실제 마디 인덱스 계산
          const actualMeasureIndex = repeatIndex * originalChordsLength + mIndex
          
          // 입력받은 코드명(예: "Am")을 우리가 정한 노트(예: "A3")로 변환
          const noteToPlay = CHORD_MAP[chordName]
          
          if (noteToPlay) {
            for (let i = 0; i < this.beatsPerMeasure; i++) {
              // 각 연주의 비트 위치 계산: 0, beatInterval, beatInterval*2, ...
              const beatPosition = i * beatInterval
              transport.schedule((time) => {
                if (this.sampler) {
                  try {
                    // 여기서 noteToPlay를 호출합니다.
                    this.sampler.triggerAttackRelease(noteToPlay, "4n", time)
                    console.log(`[GuitarPlayer] ${chordName} -> ${noteToPlay} 재생 (반복 ${repeatIndex + 1}/${this.repeatCount}, 마디 ${mIndex + 1}, 비트 위치 ${beatPosition}/${this.beatsPerMeasure}번 연주)`)
                  } catch (error) {
                    console.warn(`[GuitarPlayer] ${chordName} (${noteToPlay}) 재생 실패:`, error)
                  }
                }
              }, `${actualMeasureIndex}:${beatPosition}:0`)
            }
          } else {
            console.warn(`[GuitarPlayer] 코드 "${chordName}"에 대한 매핑을 찾을 수 없습니다`)
          }
        })
      }

      // 모든 코드 재생 완료 후 처리 (반복 횟수 고려)
      const totalMeasures = originalChordsLength * this.repeatCount
      transport.schedule(() => {
        if (this.isPlaying) {
          console.log(`[GuitarPlayer] 전체 재생 완료 (${this.repeatCount}회 반복, 총 ${totalMeasures}마디)`)
          this.isPlaying = false
          this.updateButtonState(false)
        }
      }, `${totalMeasures}:0:0`)

      // 오디오 컨텍스트가 running 상태인지 최종 확인 및 강제 활성화
      if (audioContext) {
        if (audioContext.state !== 'running') {
          console.warn("[GuitarPlayer] 오디오 컨텍스트가 running 상태가 아닙니다:", audioContext.state)
          // 여러 번 resume 시도 (모바일에서 필요)
          for (let i = 0; i < 3; i++) {
            try {
              await audioContext.resume()
              await new Promise(resolve => setTimeout(resolve, 50))
              if (audioContext.state === 'running') {
                console.log(`[GuitarPlayer] 오디오 컨텍스트 활성화 성공 (시도 ${i + 1})`)
                break
              }
            } catch (error) {
              console.error(`[GuitarPlayer] resume 시도 ${i + 1} 실패:`, error)
            }
          }
          console.log("[GuitarPlayer] Transport 시작 전 최종 상태:", audioContext.state)
        } else {
          console.log("[GuitarPlayer] ✅ 오디오 컨텍스트가 running 상태입니다")
        }
      } else {
        console.warn("[GuitarPlayer] ⚠️ 오디오 컨텍스트를 찾을 수 없습니다")
      }
      
      // 샘플러가 준비되었는지 최종 확인
      if (!this.sampler) {
        throw new Error("샘플러가 초기화되지 않았습니다.")
      }
      
      // Transport 시작 전 짧은 대기 (초기화 완료 보장, 중복 재생 방지)
      await new Promise(resolve => setTimeout(resolve, 50))
      
      transport.start()
      console.log("[GuitarPlayer] Transport 시작됨")
      
      // 모바일 디버깅: Transport 시작 직후 샘플러 테스트
      if (this.sampler && audioContext && audioContext.state === 'running') {
        try {
          // 매우 짧은 테스트 사운드 (사용자가 들리지 않을 정도로 작게)
          const testTime = transport.now() + 0.05
          this.sampler.triggerAttackRelease("C3", "16n", testTime)
          console.log("[GuitarPlayer] 모바일 테스트 사운드 재생 시도")
        } catch (error) {
          console.error("[GuitarPlayer] 모바일 테스트 사운드 실패:", error)
        }
      }
      
      // 테스트 사운드 제거: 실제 재생과 겹쳐서 두 번 들리는 문제 해결
      // 오디오 컨텍스트 활성화는 이미 위에서 완료되었으므로 테스트 사운드 불필요

    } catch (e) {
      console.error("[GuitarPlayer] 재생 중 오류:", e.message)
      console.error("[GuitarPlayer] 오류 상세:", e)
      this.isPlaying = false
      this.updateButtonState(false)
      
      // 사용자에게 오류 알림 (모바일에서 중요)
      const errorMessage = e.message || "오디오 재생에 실패했습니다"
      alert(`오디오 재생 오류: ${errorMessage}\n\n모바일에서는 사용자 인터랙션 후 오디오가 활성화됩니다. 버튼을 다시 눌러주세요.`)
    }
  }

  stop() {
    console.log("[GuitarPlayer] stop() 호출됨")
    
    // 방어 코드: sampler가 존재하는지 확인
    if (this.sampler) {
      try {
        // 모든 노트 릴리즈
        this.sampler.releaseAll()
        console.log("[GuitarPlayer] 샘플러 릴리즈 완료")
      } catch (error) {
        console.warn("[GuitarPlayer] 샘플러 릴리즈 오류:", error)
      }
    }
    
    // Transport 완전 정지 및 초기화
    if (this.tone && this.tone.Transport) {
      try {
        const transport = this.tone.Transport
        transport.stop()
        transport.cancel()
        
        // 모든 스케줄 명시적으로 제거
        if (transport.clear && typeof transport.clear === 'function') {
          transport.clear()
        }
        
        transport.position = 0
      } catch (error) {
        console.warn("[GuitarPlayer] Transport 정지 오류:", error)
      }
    }
    
    this.isPlaying = false
    this.updateButtonState(false)
    
    console.log("[GuitarPlayer] 재생 중지 완료")
  }

  updateButtonState(isPlaying) {
    if (this.hasButtonTarget) {
      const button = this.buttonTarget
      const isMobile = window.innerWidth <= 640
      
      if (isPlaying) {
        button.classList.remove("bg-green-500", "hover:bg-green-600")
        button.classList.add("bg-red-500", "hover:bg-red-600")
        // 모바일에서는 진청색 유지
        if (isMobile) {
          button.style.backgroundColor = "#1e3a8a"
        } else {
          button.style.backgroundColor = ""
        }
        // 아이콘을 정지 아이콘으로 변경
        const icon = button.querySelector("svg")
        if (icon) {
          icon.innerHTML = `
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          `
        }
      } else {
        button.classList.remove("bg-red-500", "hover:bg-red-600")
        button.classList.add("bg-green-500", "hover:bg-green-600")
        // 모바일에서는 진청색으로 설정
        if (isMobile) {
          button.style.backgroundColor = "#1e3a8a"
        } else {
          button.style.backgroundColor = ""
        }
        // 아이콘을 재생 아이콘으로 변경
        const icon = button.querySelector("svg")
        if (icon) {
          icon.innerHTML = `
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z" />
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          `
        }
      }
    }
  }
}
