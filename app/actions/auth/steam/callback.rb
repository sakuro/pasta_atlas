# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Auth
      module Steam
        class Callback < PastaAtlas::Actions::Auth::OAuthCallback
          # Steam's OpenID 2.0 callback arrives as a POST from Steam's servers
          # and does not carry our session CSRF token.
          private def verify_csrf_token(*); end
        end
      end
    end
  end
end
