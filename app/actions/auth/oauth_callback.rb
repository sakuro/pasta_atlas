# auto_register: false
# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Auth
      class OAuthCallback < PastaAtlas::Action
        include Deps[
          "operations.user.credentials.link",
          "operations.user.find_by_id",
          find_credential: "operations.user.credentials.find_by_provider_and_uid"
        ]

        def handle(request, response)
          auth = request.env["omniauth.auth"]
          halt :bad_request unless auth

          provider = auth["provider"]
          uid = auth["uid"].to_s
          info = auth["info"] || {}

          credential = find_credential.call(provider:, uid:).value_or(nil)
          logged_in_user_id = request.session[:user_id]

          if logged_in_user_id
            handle_connect(response, logged_in_user_id, credential, provider, uid)
          elsif credential
            login(request, response, credential.user_id)
          else
            request.session[:pending_auth] = {
              "provider" => provider,
              "uid" => uid,
              "login" => login_name_from(info),
              "avatar_url" => info["image"].to_s
            }
            response.redirect_to "/auth/register"
          end
        end

        private def login_name_from(info) = info["nickname"].to_s.downcase

        private def handle_connect(response, user_id, credential, provider, uid)
          user_name = find_by_id.call(user_id:).value!.name

          if credential && credential.user_id != user_id
            response.flash[:error] = "error-credential-conflict"
          elsif !credential
            result = link.call(user_id:, provider:, uid:)
            response.flash[:error] = "error-credential-conflict" if result.failure?
          end

          response.redirect_to "/@#{user_name}#tab-credentials"
        end

        private def login(request, response, user_id)
          request.session[:user_id] = user_id
          response.redirect_to routes.path(:root)
        end
      end
    end
  end
end
