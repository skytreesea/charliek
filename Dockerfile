# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t demo .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name demo demo

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.3.6
FROM ruby:$RUBY_VERSION-slim AS base

LABEL fly_launch_runtime="rails"

# Rails app lives here
WORKDIR /rails

# Update gems and bundler
RUN gem update --system --no-document && \
    gem install -N bundler

# Install base packages (bash는 bin/server 스크립트 실행에 필요)
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y bash curl libjemalloc2 libvips sqlite3 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment
ENV BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    RAILS_ENV="production"


# Throw-away build stage to reduce size of final image
FROM base AS build

# Re-declare BUNDLE_PATH for this stage (required for UndefinedVar lint check)
ENV BUNDLE_PATH="/usr/local/bundle"

# Install packages needed to build gems and compile assets
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      libffi-dev \
      libyaml-dev \
      pkg-config \
      nodejs \
      npm \
      git && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
# Set NODE_ENV for proper asset compilation
ENV NODE_ENV=production
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile


# Final stage for app image
FROM base

# Install packages needed for deployment
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y imagemagick libvips && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/sh && \
    mkdir /data && \
    chown -R 1000:1000 db log storage tmp /data bin

# Convert Windows line endings (CRLF) to Unix (LF) for all bin scripts
# 윈도우 환경에서 작업 시 발생하는 줄바꿈 문제 해결
RUN find /rails/bin -type f -name "*" -exec sed -i 's/\r$//' {} \; || true

# Ensure all executable files have proper permissions
# 모든 실행 파일에 실행 권한 부여
RUN chmod +x /rails/bin/rails /rails/bin/docker-entrypoint /rails/bin/server /rails/bin/rake || true && \
    find /rails/bin -type f -exec chmod +x {} \; || true
USER 1000:1000

# Deployment options
# DATABASE_URL은 Fly.io secrets나 환경 변수로 설정되거나, 기본값 사용
# Dockerfile lint를 통과하기 위해 기본값만 설정 (런타임에 환경 변수로 덮어쓸 수 있음)
ENV DATABASE_URL="sqlite3:///data/production.sqlite3"

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start server directly with rails server command
# CMD는 배열 형식으로 정확히 지정 (shell 형식이 아닌 exec 형식)
# 절대 경로 사용으로 Exit Code 127 방지
# -b 0.0.0.0: 모든 네트워크 인터페이스에서 리스닝
# -p 8080: 포트 명시적 지정 (puma.rb와 일치)
# EXPOSE는 문서화 목적이며, 실제 포트는 fly.toml의 internal_port와 일치해야 함
EXPOSE 8080
VOLUME /data
CMD ["/rails/bin/rails", "server", "-b", "0.0.0.0", "-p", "8080"]
