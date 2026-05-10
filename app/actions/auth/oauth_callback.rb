# auto_register: false
# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Auth
      class OauthCallback < PastaAtlas::Action
        include Deps[
          "repos.credential_repo",
          "repos.user_preference_repo",
          "operations.user.credentials.link"
        ]

        def handle(request, response)
          auth = request.env["omniauth.auth"]
          halt 400 unless auth

          provider = auth["provider"]
          uid = auth["uid"].to_s
          info = auth["info"] || {}

          credential = credential_repo.find_by_provider_and_uid(provider, uid)
          logged_in_user_id = request.session[:user_id]

          if logged_in_user_id
            handle_connect(response, logged_in_user_id, credential, provider, uid)
          elsif credential
            login(request, response, credential.user_id)
          else
            request.session[:pending_auth] = {
              "provider" => provider,
              "uid" => uid,
              "login" => info["nickname"].to_s.downcase,
              "avatar_url" => info["image"].to_s
            }
            response.redirect_to "/auth/register"
          end
        end

        private def handle_connect(response, user_id, credential, provider, uid)
          user_name = user_repo.find_by_id(user_id).name

          if credential && credential.user_id != user_id
            response.flash[:error] = "error-credential-conflict"
          elsif !credential
            result = link.call(user_id:, provider:, uid:)
            response.flash[:error] = "error-credential-conflict" if result.failure?
          end

          response.redirect_to "/@#{user_name}/edit"
        end

        private def login(request, response, user_id)
          request.session[:user_id] = user_id
          request.session[:locale] = user_preference_repo.find_by_user_id(user_id).locale
          response.redirect_to "/"
        end
      end
    end
  end
end
