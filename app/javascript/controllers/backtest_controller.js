import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tickerCheckbox", "weightInput", "cashWeight", "totalWeight", "submitButton", "startDateInput", "endDateInput", "weightSection", "weightInputs", "dateSection"]
  static values = { maxSelections: Number }

  connect() {
    this.maxSelections = this.maxSelectionsValue || 3
    // 기존 선택된 종목 유지 (체크박스 상태에서 읽어옴)
    this.selectedTickers = this.tickerCheckboxTargets
      .filter(cb => cb.checked)
      .map(cb => cb.value)
    this.weightInputs = {}
    this.updateWeightSection()
    this.updateTotalWeight()
    
    // 날짜 필드가 있으면 날짜 범위 초기화
    if (this.hasStartDateInputTarget && this.hasEndDateInputTarget) {
      this.updateDateRange()
    }
  }

  toggleTicker(event) {
    const checkbox = event.target
    const ticker = checkbox.value
    
    if (checkbox.checked) {
      // 최대 선택 개수 체크
      const checkedCount = this.tickerCheckboxTargets.filter(cb => cb.checked).length
      if (checkedCount > this.maxSelections) {
        checkbox.checked = false
        alert(`최대 ${this.maxSelections}개까지만 선택할 수 있습니다.`)
        return
      }
      
      this.selectedTickers.push(ticker)
    } else {
      // 선택 해제
      this.selectedTickers = this.selectedTickers.filter(t => t !== ticker)
      // 해당 종목의 비중 입력창 제거
      const weightRow = document.getElementById(`weight_row_${ticker}`)
      if (weightRow) {
        weightRow.remove()
      }
      delete this.weightInputs[ticker]
      
        // 종목이 하나만 남으면 첫 번째 종목을 50%로 설정 (나머지 50%는 현금)
        if (this.selectedTickers.length === 1) {
          const firstTicker = this.selectedTickers[0]
          const firstInput = this.weightInputs[firstTicker]
          if (firstInput) {
            firstInput.value = '50'
            // 슬라이더와 숫자 입력 필드도 업데이트
            const slider = document.querySelector(`input[type="range"][data-ticker="${firstTicker}"]`)
            if (slider) {
              slider.value = '50'
              const numberInput = slider.nextElementSibling
              if (numberInput && numberInput.type === 'number') {
                numberInput.value = '50'
              }
              const sliderValue = (50 - slider.min) / (slider.max - slider.min) * 100
              slider.style.background = `linear-gradient(to right, #D4A373 0%, #D4A373 ${sliderValue}%, #E5E7EB ${sliderValue}%, #E5E7EB 100%)`
            }
          }
        }
    }
    
    this.updateWeightSection()
    this.updateTotalWeight()
  }

  updateWeightSection() {
    const weightSection = this.hasWeightSectionTarget ? this.weightSectionTarget : document.getElementById('weight_section')
    const weightInputsContainer = this.hasWeightInputsTarget ? this.weightInputsTarget : document.getElementById('weight_inputs')
    const dateSection = this.hasDateSectionTarget ? this.dateSectionTarget : document.getElementById('date_section')
    
    if (this.selectedTickers.length === 0) {
      if (weightSection) weightSection.style.display = 'none'
      if (weightInputsContainer) weightInputsContainer.innerHTML = ''
      if (dateSection) dateSection.style.display = 'none'
      this.weightInputs = {}
      return
    }
    
    if (weightSection) weightSection.style.display = 'block'
    if (dateSection) dateSection.style.display = 'grid'
    
    // 비중 입력창 생성
    if (weightInputsContainer) weightInputsContainer.innerHTML = ''
    
      // 종목 선택 시 기본값 설정: 1개면 50%, 2개면 50/50, 3개면 33.3/33.3/33.3
      const tickerCount = this.selectedTickers.length
      let defaultWeightPerTicker
      if (tickerCount === 1) {
        defaultWeightPerTicker = 50 // 1개면 50% (나머지 50%는 현금)
      } else {
        defaultWeightPerTicker = Math.floor(100 / tickerCount) // 균등 분배
      }
    
    this.selectedTickers.forEach((ticker, index) => {
      const weightRow = document.createElement('div')
      weightRow.id = `weight_row_${ticker}`
      weightRow.className = 'flex items-center gap-3 p-2 rounded-lg'
      weightRow.style.backgroundColor = '#FAF9F6'
      
      const label = document.createElement('label')
      label.htmlFor = `weight_${ticker}`
      label.className = 'text-sm font-medium w-16 flex-shrink-0'
      label.style.color = '#433E3F'
      label.textContent = `${ticker}:`
      
      // 슬라이더 컨테이너
      const sliderContainer = document.createElement('div')
      sliderContainer.className = 'flex items-center gap-3 flex-1'
      
      // 숨겨진 숫자 입력 (폼 제출용)
      const hiddenInput = document.createElement('input')
      hiddenInput.type = 'hidden'
      hiddenInput.name = `weights[${ticker}]`
      hiddenInput.id = `weight_${ticker}`
      
      // 기존 값이 있으면 유지, 없으면 기본값 설정 (정수로)
      const initialValue = Math.round(parseFloat(this.weightInputs[ticker]?.value || defaultWeightPerTicker))
      
      // 다른 종목들의 합 계산 (초기 max 값 설정용)
      let otherTotal = 0
      this.selectedTickers.forEach(otherTicker => {
        if (otherTicker !== ticker) {
          const otherInput = this.weightInputs[otherTicker]
          if (otherInput) {
            otherTotal += parseFloat(otherInput.value) || 0
          }
        }
      })
      const initialMaxValue = Math.max(0, 100 - otherTotal)
      
      // 슬라이더
      const slider = document.createElement('input')
      slider.type = 'range'
      slider.min = 0
      slider.max = initialMaxValue > 0 ? initialMaxValue : 100 // 초기 max 값 설정
      slider.step = 1 // 정수 단위로 변경
      slider.value = initialValue
      slider.dataset.ticker = ticker // 티커 정보 저장
      slider.className = 'flex-1 h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer'
      // 슬라이더 스타일 (브라우저 호환성)
      slider.style.cssText = `
        width: 100%;
        height: 8px;
        border-radius: 5px;
        background: #E5E7EB;
        outline: none;
        -webkit-appearance: none;
      `
      // 초기 스타일 설정 (업데이트된 max 값 기준)
      const initialSliderValuePercent = initialMaxValue > 0 ? (parseFloat(initialValue) / initialMaxValue * 100) : 0
      slider.style.background = `linear-gradient(to right, #D4A373 0%, #D4A373 ${initialSliderValuePercent}%, #E5E7EB ${initialSliderValuePercent}%, #E5E7EB 100%)`
      
      // 숫자 입력 필드 (정수만)
      const numberInput = document.createElement('input')
      numberInput.type = 'number'
      numberInput.min = 0
      numberInput.max = 100
      numberInput.step = 1
      numberInput.value = Math.round(parseFloat(initialValue) || 0)
      numberInput.dataset.ticker = ticker
      numberInput.className = 'w-20 px-2 py-1 border rounded-lg text-sm text-center focus:ring-2 focus:outline-none'
      numberInput.style.cssText = 'border-color: #D4A37366; color: #433E3F;'
      
      // 소수점 입력 방지
      numberInput.addEventListener('keydown', (e) => {
        // 소수점(.) 입력 방지
        if (e.key === '.' || e.key === ',') {
          e.preventDefault()
        }
      })
      
      // 에러 메시지 영역
      const errorMessage = document.createElement('div')
      errorMessage.className = 'text-xs text-red-600 mt-1'
      errorMessage.id = `error_${ticker}`
      errorMessage.style.display = 'none'
      
      // 숫자 입력 필드 변경 이벤트 (실시간 검증, 경고창 없음)
      numberInput.addEventListener('input', () => {
        this.handleNumberInput(numberInput, slider, hiddenInput, ticker, errorMessage, false)
      })
      
      // 포커스가 벗어날 때 최종 검증 및 경고창 표시
      numberInput.addEventListener('blur', () => {
        this.handleNumberInput(numberInput, slider, hiddenInput, ticker, errorMessage, true)
      })
      
      hiddenInput.value = initialValue.toString()
      
      // 슬라이더 변경 이벤트
      slider.addEventListener('input', () => {
        const value = parseFloat(slider.value) || 0
        // 다른 종목들의 합 계산 (정수로)
        let otherTotal = 0
        this.selectedTickers.forEach(otherTicker => {
          if (otherTicker !== ticker) {
            const otherInput = this.weightInputs[otherTicker]
            if (otherInput) {
              otherTotal += Math.round(parseFloat(otherInput.value) || 0)
            }
          }
        })
        
        // 현재 슬라이더의 최대값 = 100 - 다른 종목들의 합 (정수로)
        const maxValue = Math.max(0, Math.floor(100 - otherTotal))
        
        // 값이 최대값을 넘으면 제한 (정수로)
        let finalValue = Math.min(Math.round(value), maxValue)
        if (finalValue < 0) finalValue = 0
        
        // 슬라이더의 max 속성 업데이트
        slider.max = maxValue > 0 ? maxValue : 0
        
        // 슬라이더와 입력값 업데이트 (정수로)
        const roundedValue = Math.round(finalValue)
        slider.value = finalValue
        hiddenInput.value = roundedValue.toString()
        numberInput.value = roundedValue.toString()
        errorMessage.style.display = 'none'
        numberInput.style.borderColor = '#D4A37366'
        
        // 슬라이더 배경 업데이트 (업데이트된 max 값 기준)
        const sliderValuePercent = maxValue > 0 ? (finalValue / maxValue * 100) : 0
        slider.style.background = `linear-gradient(to right, #D4A373 0%, #D4A373 ${sliderValuePercent}%, #E5E7EB ${sliderValuePercent}%, #E5E7EB 100%)`
        
        // 다른 슬라이더들의 최대값 업데이트
        this.updateSliderMaxValues()
        
        this.updateTotalWeight()
      })
      
      sliderContainer.appendChild(slider)
      sliderContainer.appendChild(numberInput)
      
      // 에러 메시지를 위한 컨테이너
      const inputContainer = document.createElement('div')
      inputContainer.className = 'flex flex-col'
      inputContainer.appendChild(sliderContainer)
      inputContainer.appendChild(errorMessage)
      
      weightRow.appendChild(label)
      weightRow.appendChild(inputContainer)
      weightRow.appendChild(hiddenInput)
      if (weightInputsContainer) weightInputsContainer.appendChild(weightRow)
      
      // hiddenInput을 weightInputs에 저장 (updateWeights에서 사용)
      this.weightInputs[ticker] = hiddenInput
    })
    
    // 슬라이더 최대값 초기화 및 비중 자동 계산
    this.updateSliderMaxValues()
    this.updateTotalWeight()
  }

  // 모든 슬라이더의 최대값을 업데이트 (합이 100을 넘지 않도록)
  updateSliderMaxValues() {
    this.selectedTickers.forEach(ticker => {
      const input = this.weightInputs[ticker]
      if (!input) return
      
      // 해당 티커의 슬라이더 찾기
      const slider = document.querySelector(`input[type="range"][data-ticker="${ticker}"]`)
      if (!slider) return
      
      // 다른 종목들의 합 계산 (정수로)
      let otherTotal = 0
      this.selectedTickers.forEach(otherTicker => {
        if (otherTicker !== ticker) {
          const otherInput = this.weightInputs[otherTicker]
          if (otherInput) {
            otherTotal += Math.round(parseFloat(otherInput.value) || 0)
          }
        }
      })
      
      // 현재 슬라이더의 최대값 = 100 - 다른 종목들의 합 (정수로)
      const maxValue = Math.max(0, Math.floor(100 - otherTotal))
      
      // 슬라이더의 max 속성 업데이트 (실제로 100을 넘을 수 없도록)
      slider.max = maxValue > 0 ? maxValue : 0
      
      // 현재 값이 최대값을 넘으면 조정 (정수로)
      const currentValue = Math.round(parseFloat(input.value) || 0)
      const roundedMaxValue = Math.round(maxValue)
      if (currentValue > roundedMaxValue) {
        input.value = roundedMaxValue.toString()
        slider.value = roundedMaxValue
        // 숫자 입력 필드도 업데이트
        const numberInput = slider.nextElementSibling
        if (numberInput && numberInput.type === 'number') {
          numberInput.value = roundedMaxValue.toString()
          const errorMessage = document.getElementById(`error_${ticker}`)
          if (errorMessage) {
            errorMessage.style.display = 'none'
            numberInput.style.borderColor = '#D4A37366'
          }
        }
      }
      
      // 슬라이더 배경 업데이트 (업데이트된 max 값 기준)
      const currentSliderValue = parseFloat(slider.value) || 0
      const sliderValuePercent = maxValue > 0 ? (currentSliderValue / maxValue * 100) : 0
      slider.style.background = `linear-gradient(to right, #D4A373 0%, #D4A373 ${sliderValuePercent}%, #E5E7EB ${sliderValuePercent}%, #E5E7EB 100%)`
    })
  }

  updateWeights() {
    // 슬라이더 최대값 업데이트
    this.updateSliderMaxValues()
    this.updateTotalWeight()
  }

  updateTotalWeight() {
    let total = 0
    
    // 선택된 종목의 비중 합계 (정수로)
    this.selectedTickers.forEach(ticker => {
      const input = this.weightInputs[ticker]
      if (input) {
        const value = Math.round(parseFloat(input.value) || 0)
        total += value
      }
    })
    
    // 현금 비중 계산 (100 - 종목 비중 합계, 정수로)
    const cashWeight = Math.max(0, Math.round(100 - total))
    if (this.hasCashWeightTarget) {
      this.cashWeightTarget.value = cashWeight.toString()
    }
    
    // 총합 표시 업데이트 (정수로)
    if (this.hasTotalWeightTarget) {
      const finalTotal = total + cashWeight
      this.totalWeightTarget.textContent = finalTotal.toString()
      
      // 100% 이하이면 제출 가능 (100%를 넘지 않으면 OK)
      const isValid = finalTotal <= 100.01 // 부동소수점 오차 고려
      if (isValid && total > 0) {
        this.totalWeightTarget.classList.remove("text-red-600")
        this.totalWeightTarget.classList.add("text-green-600")
        if (this.hasSubmitButtonTarget) {
          this.submitButtonTarget.disabled = false
        }
      } else {
        this.totalWeightTarget.classList.remove("text-green-600")
        this.totalWeightTarget.classList.add("text-red-600")
        if (this.hasSubmitButtonTarget) {
          this.submitButtonTarget.disabled = true
        }
      }
    }
  }

  updateDateRange() {
    if (!this.hasStartDateInputTarget || !this.hasEndDateInputTarget) return
    
    const startDate = this.startDateInputTarget.value
    const endDate = this.endDateInputTarget.value

    // 시작일이 종료일보다 늦으면 종료일을 시작일로 조정
    if (startDate && endDate && new Date(startDate) > new Date(endDate)) {
      this.endDateInputTarget.value = startDate
    }
    // 종료일이 시작일보다 빠르면 시작일을 종료일로 조정
    if (startDate && endDate && new Date(endDate) < new Date(startDate)) {
      this.startDateInputTarget.value = endDate
    }
  }

  handleNumberInput(numberInput, slider, hiddenInput, ticker, errorMessage, showAlert = false) {
    const inputValue = numberInput.value.trim()
    
    // 빈 값 처리
    if (inputValue === '') {
      errorMessage.style.display = 'none'
      numberInput.style.borderColor = '#D4A37366'
      return
    }
    
    // 숫자가 아닌 경우 (정수만 허용)
    if (isNaN(inputValue) || inputValue === '' || !/^-?\d+$/.test(inputValue)) {
      const errorText = '숫자를 입력해주세요.'
      errorMessage.textContent = errorText
      errorMessage.style.display = 'block'
      numberInput.style.borderColor = '#EF4444'
      if (showAlert) {
        alert(errorText)
        numberInput.value = Math.round(parseFloat(hiddenInput.value) || 0)
      }
      return
    }
    
    const value = parseInt(inputValue, 10)
    
    // 음수 체크
    if (value < 0) {
      const errorText = '0 이상의 숫자를 입력해주세요.'
      errorMessage.textContent = errorText
      errorMessage.style.display = 'block'
      numberInput.style.borderColor = '#EF4444'
      if (showAlert) {
        alert(errorText)
        numberInput.value = Math.round(parseFloat(hiddenInput.value) || 0)
      }
      return
    }
    
    // 100 초과 체크
    if (value > 100) {
      const errorText = '100을 넘을 수 없습니다.'
      errorMessage.textContent = errorText
      errorMessage.style.display = 'block'
      numberInput.style.borderColor = '#EF4444'
      if (showAlert) {
        alert(errorText)
        numberInput.value = Math.round(parseFloat(hiddenInput.value) || 0)
      }
      return
    }
    
    // 다른 종목들의 합 계산 (정수로)
    let otherTotal = 0
    this.selectedTickers.forEach(otherTicker => {
      if (otherTicker !== ticker) {
        const otherInput = this.weightInputs[otherTicker]
        if (otherInput) {
          otherTotal += Math.round(parseFloat(otherInput.value) || 0)
        }
      }
    })
    
    // 총합이 100을 넘는지 체크
    const total = otherTotal + value
    if (total > 100) {
      const errorText = '총 100을 넘을 수 없습니다.'
      errorMessage.textContent = errorText
      errorMessage.style.display = 'block'
      numberInput.style.borderColor = '#EF4444'
      if (showAlert) {
        alert(errorText)
        // 최대 가능한 값으로 제한 (정수로)
        const maxValue = Math.max(0, Math.floor(100 - otherTotal))
        numberInput.value = maxValue.toString()
        // 값 업데이트
        slider.value = maxValue
        hiddenInput.value = maxValue.toString()
        const sliderValuePercent = maxValue > 0 ? (maxValue / maxValue * 100) : 0
        slider.style.background = `linear-gradient(to right, #D4A373 0%, #D4A373 ${sliderValuePercent}%, #E5E7EB ${sliderValuePercent}%, #E5E7EB 100%)`
        this.updateSliderMaxValues()
        this.updateTotalWeight()
      }
      return
    }
    
    // 유효한 값인 경우
    errorMessage.style.display = 'none'
    numberInput.style.borderColor = '#D4A37366'
    
    // 최대값 계산 (정수로)
    const maxValue = Math.max(0, Math.floor(100 - otherTotal))
    
    // 값이 최대값을 넘으면 제한 (정수로)
    let finalValue = Math.min(value, maxValue)
    if (finalValue < 0) finalValue = 0
    finalValue = Math.round(finalValue)
    
    // 슬라이더의 max 속성 업데이트
    slider.max = maxValue > 0 ? maxValue : 0
    
    // 모든 값 업데이트 (정수로)
    slider.value = finalValue
    hiddenInput.value = finalValue.toString()
    numberInput.value = finalValue.toString()
    
    // 슬라이더 배경 업데이트
    const sliderValuePercent = maxValue > 0 ? (finalValue / maxValue * 100) : 0
    slider.style.background = `linear-gradient(to right, #D4A373 0%, #D4A373 ${sliderValuePercent}%, #E5E7EB ${sliderValuePercent}%, #E5E7EB 100%)`
    
    // 다른 슬라이더들의 최대값 업데이트
    this.updateSliderMaxValues()
    
    this.updateTotalWeight()
  }

  handleSubmitEnd(event) {
    // Turbo Stream 업데이트 후에도 폼이 제대로 작동하도록 재초기화
    // 결과가 표시된 후에도 다시 계산할 수 있도록 함
    setTimeout(() => {
      this.updateTotalWeight()
      if (this.hasStartDateInputTarget && this.hasEndDateInputTarget) {
        this.updateDateRange()
      }
    }, 100)
  }
}
