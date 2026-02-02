import { Controller } from "@hotwired/stimulus"

// 종목 설명 토글 컨트롤러
export default class extends Controller {
  static targets = ["description", "icon"]

  connect() {
    // 초기 상태: 설명 숨김
    const description = this.descriptionTarget
    description.style.display = "none"
    description.style.maxHeight = "0"
    description.style.overflow = "hidden"
    description.style.transition = "max-height 0.3s ease-out, opacity 0.3s ease-out, padding 0.3s ease-out"
    description.style.opacity = "0"
    description.style.paddingTop = "0"
    description.style.paddingBottom = "0"
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const description = this.descriptionTarget
    const isVisible = description.style.display !== "none" && description.style.maxHeight !== "0px"
    
    if (isVisible) {
      // 숨기기 (슬라이드 업)
      description.style.maxHeight = "0"
      description.style.opacity = "0"
      description.style.paddingTop = "0"
      description.style.paddingBottom = "0"
      setTimeout(() => {
        description.style.display = "none"
      }, 300)
    } else {
      // 보이기 (슬라이드 다운)
      description.style.display = "block"
      // 높이를 자동으로 계산하기 위해 잠시 표시
      description.style.maxHeight = "none"
      description.style.opacity = "0"
      const height = description.scrollHeight
      description.style.maxHeight = "0"
      
      // 다음 프레임에서 애니메이션 시작
      requestAnimationFrame(() => {
        description.style.paddingTop = "0.5rem"
        description.style.paddingBottom = "0.5rem"
        description.style.maxHeight = `${height + 16}px` // padding 포함
        description.style.opacity = "1"
      })
    }
  }
}
