# Pagy::Backend 로딩 문제 리포트

## 문제 요약
Rails 8.1.2 + Pagy gem 환경에서 `Pagy::Backend` 상수를 찾지 못하는 **순환 오류(Circular Error)** 상황이 발생하고 있습니다.

## 현재 상황

### 환경 정보
- **Rails 버전**: 8.1.2
- **Ruby 버전**: 3.3.6 (rbenv)
- **Pagy gem**: Gemfile 20번째 줄에 `gem "pagy"` (버전 명시 없음, 최신 유지)
- **운영체제**: WSL Ubuntu

### 현재 파일 구조

#### 1. `config/application.rb` (3번째 줄)
```ruby
require_relative "boot"

require "pagy"  # ← 현재 상태: pagy만 require

require "rails/all"
```

#### 2. `config/initializers/pagy.rb`
```ruby
# Pagy configuration
# Note: require 'pagy' and require 'pagy/backend' are already loaded in config/application.rb
# (실제로는 require 문이 없음)
```

#### 3. `app/controllers/application_controller.rb` (2번째 줄)
```ruby
class ApplicationController < ActionController::Base
  include Pagy::Backend  # ← 여기서 오류 발생
  ...
end
```

#### 4. `Gemfile` (20번째 줄)
```ruby
gem "pagy"
```

## 발생하는 두 가지 상충되는 오류

### 시나리오 A: `require 'pagy/backend'` 추가 시
**위치**: `config/application.rb` 4번째 줄에 `require "pagy/backend"` 추가

**오류 메시지**:
```
LoadError: cannot load such file -- pagy/backend (LoadError)
/home/kch/projects/charliek/config/application.rb:4:in `<main>'
```

**원인**: `pagy/backend`라는 별도 파일이 존재하지 않음.

### 시나리오 B: `require 'pagy/backend'` 제거 시 (현재 상태)
**위치**: `config/application.rb`에 `require "pagy"`만 있음

**오류 메시지**:
```
NameError (uninitialized constant Pagy::Backend):
app/controllers/application_controller.rb:2:in `<class:ApplicationController>'
```

**원인**: `require 'pagy'`만으로는 `Pagy::Backend` 모듈이 정의되지 않음.

## 시도한 해결 방법들 (모두 실패)

1. ✅ `config/application.rb`에 `require "pagy"` 추가 → 여전히 `Pagy::Backend` 찾을 수 없음
2. ❌ `config/application.rb`에 `require "pagy/backend"` 추가 → 파일이 존재하지 않음
3. ✅ `config/initializers/pagy.rb`에 `require 'pagy'` 추가 → 초기화 순서 문제로 효과 없음
4. ✅ `app/controllers/application_controller.rb` 상단에 `require 'pagy'` 추가 → 여전히 문제 발생
5. ✅ `Gemfile`에서 `gem 'pagy'` 위치를 상단으로 이동 → 효과 없음
6. ✅ `bin/spring stop` 실행 → 메모리 캐시 문제 아님

## 핵심 문제점

**이것은 전형적인 Rails Autoloading(Zeitwerk)과 Pagy gem의 초기화 순서 충돌 문제입니다.**

1. `require 'pagy'`를 실행해도 `Pagy::Backend` 모듈이 즉시 정의되지 않을 수 있음
2. `pagy/backend`라는 별도 파일은 존재하지 않음
3. `Bundler.require(*Rails.groups)`가 실행되기 전에 `require 'pagy'`를 해야 하지만, 순서를 바꿔도 해결되지 않음
4. ApplicationController가 로드될 때 `Pagy::Backend`가 아직 정의되지 않은 상태

## 질문 사항

1. **Pagy gem의 정확한 구조**: `Pagy::Backend` 모듈은 어떻게 정의되나요? `require 'pagy'`만으로 자동 로드되나요?

2. **초기화 순서**: Rails 8.1.2에서 Pagy를 올바르게 초기화하는 권장 방법은 무엇인가요?

3. **Zeitwerk 호환성**: Pagy gem이 Rails의 Zeitwerk autoloader와 호환되는가요?

4. **대안 방법**: 
   - `config/after_initialize` 블록에서 처리해야 하나요?
   - 또는 다른 초기화 방식이 필요한가요?

## 현재 상태
- ✅ Gemfile에 `gem "pagy"` 포함됨
- ✅ `config/application.rb`에 `require "pagy"` 있음
- ✅ `app/controllers/application_controller.rb`에 `include Pagy::Backend` 있음
- ❌ 서버 시작 시 오류 발생

## 재현 조건
1. `bin/spring stop` 실행
2. `bin/dev` 또는 `bin/rails s` 실행
3. 즉시 오류 발생 (서버가 시작되지 않음)
