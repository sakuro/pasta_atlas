# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Auth
      module Discord
        class Callback < PastaAtlas::Actions::Auth::OAuthCallback
          private def login_name_from(info) = info["name"].to_s.downcase
        end
      end
    end
  end
end
