import { Controller } from "@hotwired/stimulus"

// Articles#preview: 프롬프트 수정 후 기사 재생성
export default class extends Controller {
  static targets = ["regenerateBtn"]

  submit(event) {
    event.preventDefault()
    const form = this.element
    const btn = this.hasRegenerateBtnTarget ? this.regenerateBtnTarget : null

    if (btn) {
      btn.disabled = true
      btn.textContent = "재생성 중..."
    }

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
          const parser = new DOMParser()
          const doc = parser.parseFromString(html, "text/html")
          const errorMsg = doc.querySelector(".error") || doc.body
          alert("재생성 실패: " + (errorMsg.textContent || "알 수 없는 오류"))
          if (btn) {
            btn.disabled = false
            btn.textContent = "기사 재생성"
          }
        })
      })
      .catch((err) => {
        alert("재생성 실패: " + (err.message || "네트워크 오류"))
        if (btn) {
          btn.disabled = false
          btn.textContent = "기사 재생성"
        }
      })
  }
}
