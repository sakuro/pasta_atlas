# frozen_string_literal: true

require "hanami"
require "omniauth"
require "omniauth-github"

module PastaAtlas
  class App < Hanami::App
    config.actions.sessions = :cookie, {
      key: "pasta_atlas.session",
      secret: settings.session_secret,
      expire_after: 60 * 60 * 24 * 365
    }

    config.middleware.use OmniAuth::Builder do
      provider :github,
        PastaAtlas::App.settings.github_client_id,
        PastaAtlas::App.settings.github_client_secret,
        scope: "read:user"
    end

    config.actions.content_security_policy[:form_action] += " https://github.com"
    config.actions.content_security_policy[:img_src] += " blob:"

    if Hanami.env?(:development)
      config.actions.content_security_policy[:connect_src] += " http://localhost:4566"
      config.actions.content_security_policy[:img_src] += " http://localhost:4566"
    end
  end
end
