import { Controller } from "@hotwired/stimulus"

// Articles#new: 추천 키워드 드래그/클릭, 2~6개 검증, 기사 생성 시 로딩 → 미리보기
export default class extends Controller {
  static targets = [
    "submitBtn", "keywordsInput", "keywordsHidden", "dropZone", "selectedChips",
    "keywordCount", "keywordError", "recommendedChip"
  ]
  static values = { newUrl: String }

  static loadingHtml = `
    <div class="flex flex-col items-center justify-center py-16 px-6 rounded-xl border-2 border-dashed border-gray-200 bg-gray-50">
      <svg class="animate-spin h-12 w-12 text-blue-600 mb-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" aria-hidden="true">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
      <p class="text-lg font-medium text-gray-700">AI가 기사를 작성 중입니다...</p>
      <p class="mt-1 text-sm text-gray-500">잠시만 기다려 주세요.</p>
    </div>
  `

  connect() {
    this.committedKeywords = []
    if (this.hasKeywordsHiddenTarget) {
      const initial = this.keywordsHiddenTarget.value || ""
      this.committedKeywords = this.uniqueKeywords(this.parseKeywords(initial))
    }
    if (this.hasKeywordsInputTarget) {
      this.keywordsInputTarget.value = ""
      this.keywordsInputTarget.addEventListener("input", () => this.syncFromInput())
      this.keywordsInputTarget.addEventListener("change", () => this.syncFromInput())
    }
    this.applyState()
  }

  getFullList() {
    const current = (this.keywordsInputTarget?.value || "").trim()
    return [...this.committedKeywords, ...(current ? [current] : [])]
  }

  updateHidden() {
    if (this.hasKeywordsHiddenTarget) {
      this.keywordsHiddenTarget.value = this.getFullList().join(", ")
    }
  }

  applyState() {
    this.updateHidden()
    this.renderChips(this.committedKeywords)
    this.updateCount(this.getFullList().length)
    this.hideError()
  }

  // 쉼표로 키워드 구분
  parseKeywords(str) {
    if (!str || !str.trim()) return []
    return str.split(",").map(s => s.trim()).filter(Boolean)
  }

  uniqueKeywords(list) {
    return [...new Set(list)]
  }

  syncFromInput() {
    if (!this.hasKeywordsInputTarget) return
    const raw = this.keywordsInputTarget.value
    // 쉼표를 찍는 순간 앞 구간 → 칩으로 확정, 입력란 비워서 새 키워드/드래그앤드롭 대기
    const parts = raw.split(",").map(s => s.trim())
    const newCommit = parts.slice(0, -1).filter(Boolean)
    this.committedKeywords = this.uniqueKeywords([...this.committedKeywords, ...newCommit])
    const currentInput = parts.length > 0 ? parts[parts.length - 1] : ""
    this.keywordsInputTarget.value = currentInput
    this.applyState()
  }

  renderChips(list) {
    if (!this.hasSelectedChipsTarget) return
    this.selectedChipsTarget.innerHTML = list.map(kw => `
      <span class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-sm bg-blue-100 text-blue-800 border border-blue-200 dark:bg-blue-900/50 dark:text-blue-200 dark:border-blue-700">
        ${this.escapeHtml(kw)}
        <button type="button" class="ml-0.5 leading-none text-blue-600 hover:text-blue-800 dark:text-blue-300 dark:hover:text-blue-100" data-keyword="${this.escapeHtml(kw)}" data-action="click->article-generate#removeKeyword" aria-label="제거">×</button>
      </span>
    `).join("")
  }

  escapeHtml(s) {
    const div = document.createElement("div")
    div.textContent = s
    return div.innerHTML
  }

  updateCount(n) {
    if (this.hasKeywordCountTarget) this.keywordCountTarget.textContent = n
  }

  showError(msg) {
    if (this.hasKeywordErrorTarget) {
      this.keywordErrorTarget.textContent = msg
      this.keywordErrorTarget.classList.remove("hidden")
    }
  }

  hideError() {
    if (this.hasKeywordErrorTarget) {
      this.keywordErrorTarget.textContent = ""
      this.keywordErrorTarget.classList.add("hidden")
    }
  }

  addKeyword(event) {
    const chip = event.currentTarget
    const kw = (chip.dataset.keyword || chip.textContent || "").trim()
    if (!kw) return
    if (this.committedKeywords.includes(kw)) return
    if (this.getFullList().length >= 6) {
      this.showError("키워드는 최대 6개까지 선택할 수 있습니다.")
      return
    }
    this.committedKeywords = this.uniqueKeywords([...this.committedKeywords, kw])
    this.applyState()
  }

  removeKeyword(event) {
    event.preventDefault()
    event.stopPropagation()
    const btn = event.currentTarget
    const kw = btn.dataset.keyword || ""
    if (!kw) return
    this.committedKeywords = this.committedKeywords.filter(k => k !== kw)
    this.applyState()
  }

  dragStart(event) {
    const kw = (event.currentTarget.dataset.keyword || event.currentTarget.textContent || "").trim()
    event.dataTransfer.setData("text/plain", kw)
    event.dataTransfer.effectAllowed = "copy"
  }

  dragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "copy"
    if (this.hasDropZoneTarget) this.dropZoneTarget.classList.add("ring-2", "ring-blue-400")
  }

  drop(event) {
    event.preventDefault()
    if (this.hasDropZoneTarget) this.dropZoneTarget.classList.remove("ring-2", "ring-blue-400")
    const kw = (event.dataTransfer.getData("text/plain") || "").trim()
    if (!kw) return
    if (this.committedKeywords.includes(kw)) return
    if (this.getFullList().length >= 6) {
      this.showError("키워드는 최대 6개까지 선택할 수 있습니다.")
      return
    }
    this.committedKeywords = this.uniqueKeywords([...this.committedKeywords, kw])
    this.applyState()
  }

  focusInput(event) {
    if (event.target === this.dropZoneTarget || this.dropZoneTarget?.contains(event.target)) {
      if (this.hasKeywordsInputTarget) this.keywordsInputTarget.focus()
    }
  }

  submit(event) {
    event.preventDefault()
    const form = this.element
    const frame = form.closest("turbo-frame")
    if (!frame) return

    this.syncFromInput()
    const list = this.getFullList()
    if (list.length < 2) {
      this.showError("키워드는 최소 2개 이상 입력해 주세요.")
      return
    }
    if (list.length > 6) {
      this.showError("키워드는 6개 이하여야 합니다.")
      return
    }
    this.hideError()

    const newUrl = this.hasNewUrlValue ? this.newUrlValue : "/articles/new"
    if (this.hasSubmitBtnTarget) this.submitBtnTarget.disabled = true
    frame.innerHTML = this.constructor.loadingHtml

    const formData = new FormData(form)
    fetch(form.action, {
      method: "POST",
      body: formData,
      headers: {
        "Accept": "text/html",
        "X-Requested-With": "XMLHttpRequest"
      },
      redirect: "follow"
    })
      .then((res) => {
        if (res.redirected) {
          window.location.href = res.url
          return
        }
        if (res.ok) return res.text().then((html) => {
          document.open()
          document.write(html)
          document.close()
        })
        return res.text().then((html) => {
          frame.innerHTML = html
        })
      })
      .catch((err) => {
        frame.innerHTML = `
          <div class="p-4 bg-red-100 text-red-700 rounded-lg">
            <p class="font-semibold">요청 실패</p>
            <p class="mt-1 text-sm">${err.message || "네트워크 오류가 발생했습니다."}</p>
            <a href="${newUrl}" data-turbo-frame="_top" class="mt-3 inline-block text-sm underline">다시 시도</a>
          </div>
        `
      })
  }
}
