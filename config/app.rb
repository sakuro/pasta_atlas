# frozen_string_literal: true

require "hanami"

module PastaAtlas
  class App < Hanami::App
    config.actions.sessions = :cookie, {
      key: "pasta_atlas.session",
      secret: settings.session_secret,
      expire_after: 60 * 60 * 24 * 365
    }
  end
end
