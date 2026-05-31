# auto_register: false
# frozen_string_literal: true

require "rack/protection"

module PastaAtlas
  module Views
    class Context < Hanami::View::Context
      def omniauth_authenticity_token
        Rack::Protection::AuthenticityToken.token(session)
      end
    end
  end
end
