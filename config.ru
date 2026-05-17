# frozen_string_literal: true

require "hanami/boot"

if Hanami.env?(:development)
  # In watch mode, assets (app.css, FTL files, etc.) are served with non-hashed URLs,
  # making them susceptible to browser caching between rebuilds.
  #
  # config.middleware.use cannot solve this: user middlewares are appended after
  # Hanami::Middleware::Assets in the Rack stack (see hanami/slice.rb), so Rack::Static
  # short-circuits asset requests before inner middlewares are ever called.
  #
  # Wrapping Hanami.app here places this middleware outside Hanami::Middleware::Assets,
  # allowing it to add Cache-Control: no-cache to asset responses.
  use(Class.new do
    def initialize(app) = @app = app

    def call(env)
      status, headers, body = @app.call(env)
      headers["cache-control"] = "no-cache" if env["PATH_INFO"].start_with?("/assets/")
      [status, headers, body]
    end
  end)
end

run Hanami.app
