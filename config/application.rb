require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Charliek
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # 한국 시간대 설정 (KST, UTC+9)
    config.time_zone = "Seoul"
    # config.eager_load_paths << Rails.root.join("extras")

    # 한국어 로케일 설정
    config.i18n.default_locale = :ko
    config.i18n.available_locales = [:ko, :en]
    
    # Canonical Domain 미들웨어 등록 (정적 파일 포함 모든 요청 처리)
    # lib/ 디렉토리에서 미들웨어 로드
    # ActionDispatch::Static보다 먼저 실행하여 ads.txt를 직접 서빙할 수 있도록 함
    require_relative '../lib/canonical_domain_middleware'
    config.middleware.insert_before ActionDispatch::Static, CanonicalDomainMiddleware
  end
end
