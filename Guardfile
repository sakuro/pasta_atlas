# frozen_string_literal: true

group :server do
  guard "puma", port: ENV.fetch("HANAMI_PORT", 2300), environment: ENV.fetch("HANAMI_ENV", "development") do
    # Edit the following regular expression for your needs.
    # See: https://hanakai.org/learn/hanami/v3.0/app/code-reloading
    watch(%r{^(app|config|lib|slices)(/[^/]+)*.(rb|erb|haml|slim)$}i)
  end
end
