# syntax=docker/dockerfile:1

# ---- Builder: Ruby + Node for asset compilation ----
FROM ruby:4.0.5-slim AS builder

ARG NODE_MAJOR=25

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      curl \
      gnupg \
      libpq-dev \
      libyaml-dev && \
    curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development:test"

COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3 && \
    rm -rf /usr/local/bundle/ruby/*/cache \
           /usr/local/bundle/ruby/*/doc \
           /usr/local/bundle/ruby/*/build_info

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

RUN SESSION_SECRET=dummy \
    GITHUB_CLIENT_ID=dummy \
    GITHUB_CLIENT_SECRET=dummy \
    DISCORD_CLIENT_ID=dummy \
    DISCORD_CLIENT_SECRET=dummy \
    STEAM_WEB_API_KEY=dummy \
    S3_BUCKET=dummy \
    CLOUDFRONT_BASE_URL=https://dummy.example.com \
    SQS_S3_CLEANUP_QUEUE_URL=https://dummy.example.com/dummy \
    HANAMI_ENV=production \
    bundle exec hanami assets compile && \
    npm run build:islands

# ---- Runtime: minimal image with pre-built artifacts ----
FROM ruby:4.0.5-slim AS runtime

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends libpq-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app/app ./app
COPY --from=builder /app/config ./config
COPY --from=builder /app/config.ru ./config.ru
COPY --from=builder /app/Gemfile ./Gemfile
COPY --from=builder /app/Gemfile.lock ./Gemfile.lock
COPY --from=builder /app/lib ./lib
COPY --from=builder /app/public ./public
COPY --from=builder /app/Rakefile ./Rakefile

RUN groupadd --gid 1000 app && \
    useradd --uid 1000 --gid app --no-create-home app && \
    chown -R app:app /app

USER app

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development:test" \
    HANAMI_ENV=production \
    HANAMI_PORT=3000 \
    HOME=/app

EXPOSE 3000

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
