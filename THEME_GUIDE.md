# 테마 관리 가이드

## 색상 변경하기

### 1. CSS 변수 수정 (`app/assets/tailwind/application.css`)

```css
:root {
  --theme-bg: #FAF9F6;          /* 배경색 */
  --theme-card: #FFFFFF;         /* 카드 배경색 */
  --theme-primary: #D4A373;      /* 포인트 색상 (버튼, 링크 등) */
  --theme-text: #433E3F;         /* 텍스트 색상 */
  --theme-border: rgba(212, 163, 115, 0.2);  /* 테두리 색상 */
  --theme-hover: rgba(212, 163, 115, 0.15);  /* 호버 배경색 */
}
```

### 2. Tailwind 설정 수정 (`tailwind.config.js`)

```javascript
colors: {
  'theme-bg': '#FAF9F6',
  'theme-card': '#FFFFFF',
  'theme-primary': '#D4A373',
  'theme-text': '#433E3F',
  'theme-border': 'rgba(212, 163, 115, 0.2)',
  'theme-hover': 'rgba(212, 163, 115, 0.15)',
}
```

## 폰트 변경하기

### CSS 변수 수정 (`app/assets/tailwind/application.css`)

```css
:root {
  --font-heading: 'Noto Sans KR', sans-serif;    /* 제목 (h1, h2, h3 등) */
  --font-body: 'Noto Sans KR', sans-serif;       /* 본문 텍스트 */
  --font-button: 'Noto Sans KR', sans-serif;     /* 버튼 텍스트 */
  --font-link: 'Noto Sans KR', sans-serif;       /* 링크 텍스트 */
  --font-nav: 'Noto Sans KR', sans-serif;        /* 네비게이션 메뉴 */
  --font-code: 'Courier New', monospace;         /* 코드/고정폭 텍스트 */
  --font-footer: 'Noto Sans KR', sans-serif;     /* 푸터 텍스트 */
}
```

### Tailwind 설정 수정 (`tailwind.config.js`)

`fontFamily` 섹션도 동일한 폰트로 수정:

```javascript
fontFamily: {
  'theme-heading': ['var(--font-heading)', 'system-ui', 'sans-serif'],
  'theme-body': ['var(--font-body)', 'system-ui', 'sans-serif'],
  // ...
}
```

## 뷰 파일에서 사용하기

### 색상 클래스
- `bg-theme` - 배경색
- `bg-theme-card` - 카드 배경색
- `bg-theme-primary` - 포인트 배경색
- `text-theme` - 텍스트 색상
- `text-theme-primary` - 포인트 텍스트 색상
- `border-theme` - 테두리 색상

### 폰트 클래스
- `font-theme-heading` - 제목 폰트
- `font-theme-body` - 본문 폰트
- `font-theme-button` - 버튼 폰트
- `font-theme-link` - 링크 폰트
- `font-theme-nav` - 네비게이션 폰트
- `font-theme-code` - 코드 폰트
- `font-theme-footer` - 푸터 폰트

## 예시

```erb
<!-- 제목 -->
<h1 class="font-theme-heading text-theme">제목</h1>

<!-- 본문 -->
<p class="font-theme-body text-theme">본문 텍스트</p>

<!-- 버튼 -->
<button class="font-theme-button bg-theme-primary text-white">버튼</button>

<!-- 링크 -->
<a href="#" class="font-theme-link text-theme-primary">링크</a>

<!-- 네비게이션 -->
<nav class="font-theme-nav">
  <a href="#" class="text-theme">메뉴</a>
</nav>
```
