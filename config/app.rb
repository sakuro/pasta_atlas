# frozen_string_literal: true

require "hanami"
require "omniauth"
require "omniauth-discord"
require "omniauth-github"
require "rack/icu4x/locale"
require_relative "../app/i18n"

module PastaAtlas
  class App < Hanami::App
    config.actions.sessions = :cookie, {
      key: "pasta_atlas.session",
      secret: settings.session_secret,
      expire_after: 60 * 60 * 24 * 365
    }

    config.middleware.use Rack::ICU4X::Locale,
      locales: PastaAtlas::I18n::SUPPORTED_LOCALES,
      detectors: [
        ->(env) { env.dig("rack.session", "locale") },
        :header
      ],
      default: "en"

    config.middleware.use OmniAuth::Builder do
      provider :discord,
        PastaAtlas::App.settings.discord_client_id,
        PastaAtlas::App.settings.discord_client_secret,
        scope: "identify"
      provider :github,
        PastaAtlas::App.settings.github_client_id,
        PastaAtlas::App.settings.github_client_secret,
        scope: "read:user"
    end

    config.actions.content_security_policy[:form_action] += " https://discord.com https://github.com"
    config.actions.content_security_policy[:img_src] += " blob:"
    config.actions.content_security_policy[:script_src] += " 'nonce'"

    if Hanami.env?(:development)
      config.actions.content_security_policy[:connect_src] += " http://localhost:4566"
      config.actions.content_security_policy[:img_src] += " http://localhost:4566"
    end
  end
end
