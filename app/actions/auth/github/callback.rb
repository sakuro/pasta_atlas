# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Auth
      module Github
        class Callback < PastaAtlas::Action
          include Deps[
            "repos.credential_repo",
            "repos.user_preference_repo",
            "repos.user_profile_repo"
          ]

          def handle(request, response)
            auth = request.env["omniauth.auth"]
            halt 400 unless auth

            provider = auth["provider"]
            uid = auth["uid"].to_s
            info = auth["info"] || {}

            credential = credential_repo.find_by_provider_and_uid(provider, uid)

            if credential
              request.session[:user_id] = credential.user_id
              # Rack::ICU4X::Locale middleware cannot access the database; mirror the user's locale preference in the session for locale detection.
              request.session[:locale] = user_preference_repo.find_by_user_id(credential.user_id).locale
              response.redirect_to "/"
            else
              # New user: store auth info in session and redirect to registration
              request.session[:pending_auth] = {
                "provider" => provider,
                "uid" => uid,
                "login" => info["nickname"].to_s.downcase,
                "avatar_url" => info["image"].to_s
              }
              response.redirect_to "/auth/register"
            end
          end
        end
      end
    end
  end
end
