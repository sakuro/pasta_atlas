# syntax=docker/dockerfile:1

# ---- Builder: Ruby + Node for asset compilation ----
FROM ruby:4.0.3-slim AS builder

ARG NODE_MAJOR=25

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      curl \
      gnupg \
      libpq-dev && \
    curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development:test"

COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

RUN bundle exec hanami assets compile && \
    npm run build:islands

# ---- Runtime: minimal image with pre-built artifacts ----
FROM ruby:4.0.3-slim AS runtime

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends libpq-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app .

RUN groupadd --gid 1000 app && \
    useradd --uid 1000 --gid app --no-create-home app && \
    chown -R app:app /app

USER app

ENV BUNDLE_PATH=/usr/local/bundle \
    HANAMI_ENV=production \
    HANAMI_PORT=3000

EXPOSE 3000

CMD ["bundle", "exec", "hanami", "server"]
