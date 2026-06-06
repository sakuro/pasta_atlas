# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Auth
      module Steam
        class Callback < PastaAtlas::Actions::Auth::OAuthCallback
          def handle(request, response)
            # Reject callbacks not initiated through our own /auth/steam to prevent login CSRF.
            halt :bad_request unless request.session.delete(:steam_pending)
            super
          end

          # Steam's OpenID 2.0 GET callback does not carry our session CSRF token.
          private def verify_csrf_token(*); end
        end
      end
    end
  end
end
