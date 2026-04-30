# frozen_string_literal: true

require "hanami"

module PastaAtlas
  class App < Hanami::App
    config.actions.sessions = :cookie, {
      key: "pasta_atlas.session",
      secret: settings.session_secret,
      expire_after: 60 * 60 * 24 * 365
    }

    if Hanami.env?(:development)
      config.actions.content_security_policy[:connect_src] += " http://localhost:4566"
      config.actions.content_security_policy[:img_src] += " http://localhost:4566"
    end
  end
end
