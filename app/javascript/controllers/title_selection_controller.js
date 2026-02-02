import { Controller } from "@hotwired/stimulus"

// Articles#title_selection: 제목 선택 시 라디오 버튼 스타일 업데이트
export default class extends Controller {
  connect() {
    const radios = this.element.querySelectorAll(".title-radio")
    radios.forEach(radio => {
      radio.addEventListener("change", () => this.updateStyles())
    })
  }

  updateStyles() {
    const labels = this.element.querySelectorAll(".title-option")
    labels.forEach(label => {
      const radio = label.querySelector(".title-radio")
      if (radio && radio.checked) {
        label.classList.add("border-blue-600", "dark:border-blue-500", "bg-blue-50", "dark:bg-blue-900/30")
      } else {
        label.classList.remove("border-blue-600", "dark:border-blue-500", "bg-blue-50", "dark:bg-blue-900/30")
      }
    })
  }
}
