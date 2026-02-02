# Pagy 43.x + Rails 8.1.2 해결 가이드

## 🎯 문제 요약

Rails 8.1.2 환경에서 Pagy 43.2.6을 사용할 때 발생한 주요 문제들:

1. **`NameError: uninitialized constant Pagy::Backend`** - 서버 부팅 실패
2. **`FrozenError: can't modify frozen Hash`** - Pagy::DEFAULT 수정 시도 시 발생
3. **`LoadError: cannot load such file -- pagy/extras/bootstrap`** - 존재하지 않는 extras 파일 require
4. **`already initialized constant ActionController::Base::MODULES`** - 중복 로딩 문제

---

## ✅ 최종 해결책 (Pagy 43.x 방식)

### 핵심 원칙

**Pagy 43.x는 이전 버전(Pagy 9.x 이하)과 완전히 다른 아키텍처를 사용합니다:**

- ❌ `Pagy::Backend` / `Pagy::Frontend` 없음
- ✅ `Pagy::Method` 사용
- ❌ `Pagy::DEFAULT.merge!` / `Pagy::DEFAULT[:key]` 수정 불가 (Frozen)
- ✅ `Pagy.options[:key]` 사용
- ❌ `pagy/extras/bootstrap` 같은 require 방식 없음
- ❌ `items:` 파라미터 없음
- ✅ `limit:` 파라미터 사용

---

## 📋 단계별 해결 방법

### 1. Gemfile 확인

```ruby
# Gemfile
gem "pagy"  # 버전 명시 없이 최신 유지 (43.x)
```

**확인 방법:**
```bash
bundle exec ruby -e 'require "pagy"; puts Pagy::VERSION'
# 출력: 43.2.6 (예시)
```

---

### 2. config/initializers/pagy.rb 설정

**✅ 올바른 설정 (최종):**

```ruby
# frozen_string_literal: true

# Pagy 43+ initializer (no extras, no DEFAULT.merge!)
Pagy.options[:limit] = 20
# 필요시:
# Pagy.options[:client_max_limit] = 100
```

**❌ 잘못된 설정 (절대 사용 금지):**

```ruby
# ❌ 이렇게 하면 안 됩니다!

# 1. Pagy::DEFAULT 수정 시도 (FrozenError 발생)
Pagy::DEFAULT[:limit] = 20
Pagy::DEFAULT.merge!(limit: 20)
Pagy::DEFAULT[:overflow] = :last_page

# 2. 존재하지 않는 extras require (LoadError 발생)
require 'pagy/extras/bootstrap'
require 'pagy/extras/overflow'
require 'pagy/backend'

# 3. 레거시 훅 방식 (중복 로딩 문제)
ActiveSupport.on_load(:action_controller) { include Pagy::Backend }
ActiveSupport.on_load(:action_view) { include Pagy::Frontend }
```

---

### 3. app/controllers/application_controller.rb 설정

**✅ 올바른 설정:**

```ruby
class ApplicationController < ActionController::Base
  include Pagy::Method  # Pagy 43.x 방식

  # ... 나머지 코드
end
```

**❌ 잘못된 설정:**

```ruby
# ❌ Pagy 9.x 이하 방식 (작동하지 않음)
class ApplicationController < ActionController::Base
  include Pagy::Backend  # NameError 발생!
end
```

---

### 4. 컨트롤러에서 pagy 사용법

**✅ 올바른 사용 (Pagy 43.x):**

```ruby
class PostsController < ApplicationController
  def index
    posts_scope = Post.all.order(created_at: :desc)
    
    # Pagy 43.x 방식
    @pagy, @posts = pagy(:offset, posts_scope, limit: 20)
    # 반환값: [Pagy 객체, records 배열]
  end
end
```

**❌ 잘못된 사용 (레거시 방식):**

```ruby
# ❌ Pagy 9.x 이하 방식 (작동하지 않음)
@pagy, @posts = pagy(posts_scope, items: 20)  # items는 존재하지 않음
@pagy = pagy(:offset, posts_scope, items: 20)  # 반환값이 다름
```

**차이점:**
- `items:` → `limit:` 변경
- 반환값: `[Pagy 객체, records 배열]` (2개 값)
- 첫 번째 파라미터로 `:offset` 명시 필요

---

### 5. 뷰에서 페이지네이션 표시

**✅ 올바른 사용 (Pagy 43.x):**

```erb
<%# app/views/posts/index.html.erb %>
<% if @posts.any? %>
  <div class="py-6 flex justify-center">
    <%= @pagy.series_nav.html_safe %>
  </div>
<% end %>
```

**❌ 잘못된 사용 (레거시 방식):**

```erb
<%# ❌ Pagy 9.x 이하 방식 (작동하지 않음) %>
<%= pagy_nav(@pagy).html_safe %>
<%= pagy_bootstrap_nav(@pagy).html_safe %>
```

**차이점:**
- `pagy_nav` helper 메서드 없음
- `@pagy.series_nav` 메서드 직접 호출

---

### 6. config/application.rb 확인

**✅ 올바른 설정:**

```ruby
require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile
Bundler.require(*Rails.groups)  # Gemfile의 pagy가 여기서 자동 로드됨

# ❌ 수동 require 불필요!
# require "pagy"  # 필요 없음
```

**중요:** `Bundler.require(*Rails.groups)`가 Gemfile의 모든 gem을 자동으로 로드하므로 `require "pagy"`는 **필요 없습니다**.

---

### 7. app/helpers/application_helper.rb 확인

**✅ 올바른 설정 (Pagy 43.x):**

```ruby
module ApplicationHelper
  # Pagy::Frontend는 필요 없음 (43.x에서는 사용하지 않음)
end
```

**❌ 잘못된 설정:**

```ruby
# ❌ Pagy 9.x 이하 방식
module ApplicationHelper
  include Pagy::Frontend  # 필요 없음 (또는 에러 발생 가능)
end
```

---

## 🔍 문제 진단 체크리스트

서버가 제대로 부팅되지 않는다면 다음을 확인하세요:

- [ ] `config/initializers/pagy.rb`에 `Pagy::DEFAULT` 수정 코드가 있는가?
- [ ] `require 'pagy/extras/bootstrap'` 같은 코드가 있는가?
- [ ] `config/application.rb`에 `require "pagy"`가 있는가?
- [ ] `ApplicationController`에 `include Pagy::Backend`가 있는가?
- [ ] 컨트롤러에서 `items:` 파라미터를 사용하고 있는가?
- [ ] 뷰에서 `pagy_nav()` 같은 helper를 사용하고 있는가?

**하나라도 체크되면 레거시 방식이므로 Pagy 43.x 방식으로 변경해야 합니다.**

---

## 📝 완전한 예제

### 초기화 파일

```ruby
# config/initializers/pagy.rb
# frozen_string_literal: true

Pagy.options[:limit] = 20
```

### 컨트롤러

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Pagy::Method
end

# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def index
    posts_scope = Post.all.order(created_at: :desc)
    @pagy, @posts = pagy(:offset, posts_scope, limit: 20)
  end
end
```

### 뷰

```erb
<%# app/views/posts/index.html.erb %>
<% @posts.each do |post| %>
  <%= post.title %>
<% end %>

<div class="pagination">
  <%= @pagy.series_nav.html_safe %>
</div>
```

---

## 🚀 서버 재시작

변경 사항 적용을 위해:

```bash
bin/spring stop
bin/dev
# 또는
bin/rails server
```

---

## 📚 참고 자료

- **Pagy 43.x 공식 문서**: [https://ddnexus.github.io/pagy/](https://ddnexus.github.io/pagy/)
- **Rails 8.1.2 문서**: [https://guides.rubyonrails.org/](https://guides.rubyonrails.org/)

---

## ⚠️ 주의사항

1. **버전 확인 필수**: Pagy 버전이 43.x인지 반드시 확인하세요
   ```bash
   bundle exec ruby -e 'require "pagy"; puts Pagy::VERSION'
   ```

2. **레거시 문서 주의**: Pagy 9.x 이하 문서를 참고하면 안 됩니다. 아키텍처가 완전히 다릅니다.

3. **FrozenError**: `Pagy::DEFAULT`는 절대 수정하면 안 됩니다. `Pagy.options`를 사용하세요.

4. **중복 로딩**: `ActiveSupport.on_load` 훅과 직접 `include`를 동시에 사용하지 마세요.

---

## ✨ 해결 완료 체크리스트

- [x] `config/initializers/pagy.rb` - Pagy.options 사용
- [x] `app/controllers/application_controller.rb` - include Pagy::Method
- [x] 컨트롤러 pagy 호출 - `limit:` 사용, `@pagy, @posts` 반환값
- [x] 뷰 페이지네이션 - `@pagy.series_nav` 사용
- [x] 모든 레거시 require 제거
- [x] 서버 정상 부팅 확인

---

**최종 업데이트**: 2025-01-XX  
**테스트 환경**: Rails 8.1.2, Pagy 43.2.6, Ruby 3.3.6, WSL Ubuntu
