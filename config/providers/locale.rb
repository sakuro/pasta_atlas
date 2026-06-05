# frozen_string_literal: true

require "json"

Hanami.app.register_provider(:locale, namespace: true) do
  start do
    supported_locales = JSON.parse(
      Hanami.app.root.join("config/supported_locales.json").read
    ).freeze
    register "supported_locales", supported_locales
  end
end
