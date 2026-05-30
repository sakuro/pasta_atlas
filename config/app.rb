# frozen_string_literal: true

require "hanami"
require "omniauth"
require_relative "../app/middleware/reverse_proxy_fix"
require "omniauth-discord"
require "omniauth-github"
require "omniauth-steam"
require "rack/icu4x/locale"
require_relative "../app/i18n"

module PastaAtlas
  class App < Hanami::App
    config.inflections do |i|
      i.acronym "OAuth"
    end

    config.actions.sessions = :cookie, {
      key: "pasta_atlas.session",
      secret: settings.session_secret,
      expire_after: 60 * 60 * 24 * 365,
      secure: Hanami.env?(:production)
    }

    config.middleware.use Rack::ICU4X::Locale,
      locales: PastaAtlas::I18n::SUPPORTED_LOCALES,
      detectors: [
        ->(env) { env.dig("rack.session", "locale") },
        :header
      ],
      default: "en"

    OmniAuth.config.failure_raise_out_environments = []

    if (base_url = ENV.fetch("APP_BASE_URL", nil))
      OmniAuth.config.full_host = base_url
      config.middleware.use PastaAtlas::Middleware::ReverseProxyFix, base_url:
    end

    config.middleware.use OmniAuth::Builder do
      provider :discord,
        PastaAtlas::App.settings.discord_client_id,
        PastaAtlas::App.settings.discord_client_secret,
        scope: "identify"
      provider :github,
        PastaAtlas::App.settings.github_client_id,
        PastaAtlas::App.settings.github_client_secret,
        scope: "read:user"
      provider :steam,
        PastaAtlas::App.settings.steam_web_api_key
    end

    config.actions.content_security_policy[:form_action] += " https://discord.com https://github.com https://steamcommunity.com"
    config.actions.content_security_policy[:img_src] += " blob: https://avatars.steamstatic.com"
    config.actions.content_security_policy[:script_src] += " 'nonce'"

    if Hanami.env?(:development)
      config.actions.content_security_policy[:connect_src] += " http://localhost:4566"
      config.actions.content_security_policy[:img_src] += " http://localhost:4566"
    else
      s3_origin = "https://#{settings.s3_bucket}.s3.#{settings.aws_region}.amazonaws.com"
      cloudfront_origin = settings.cloudfront_base_url.to_s
      config.actions.content_security_policy[:connect_src] += " #{s3_origin} #{cloudfront_origin}"
      config.actions.content_security_policy[:img_src] += " #{cloudfront_origin}"
    end
  end
end
