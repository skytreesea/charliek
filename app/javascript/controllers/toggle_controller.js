import { Controller } from "@hotwired/stimulus"

// 아이콘 클릭 시 내용 토글 (친근한 소개 섹션용)
export default class extends Controller {
  static targets = ["content", "iconOpen", "iconClose", "trigger"]

  toggle() {
    if (!this.hasContentTarget) return

    const isHidden = this.contentTarget.classList.contains("hidden")
    this.contentTarget.classList.toggle("hidden", !isHidden)

    if (this.hasIconOpenTarget && this.hasIconCloseTarget) {
      this.iconOpenTarget.classList.toggle("hidden", isHidden)
      this.iconCloseTarget.classList.toggle("hidden", !isHidden)
    }
  }
}
