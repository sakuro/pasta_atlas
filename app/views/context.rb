# auto_register: false
# frozen_string_literal: true

require "rack/protection"

module PastaAtlas
  module Views
    class Context < Hanami::View::Context
      include Deps["routes"]

      def path(...) = routes.path(...)
      def url(...) = routes.url(...)

      def omniauth_authenticity_token
        Rack::Protection::AuthenticityToken.token(session)
      end
    end
  end
end
