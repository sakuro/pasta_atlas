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
          logged_in_user = find_logged_in_user(request)

          if logged_in_user
            handle_connect(response, logged_in_user, credential, provider, uid)
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

        # A session can outlive its user, for example when the account is deleted from another
        # device.
        private def find_logged_in_user(request)
          user_id = request.session[:user_id]
          return unless user_id

          find_by_id.call(user_id:).value_or do
            # Treat a vanished user as signed out; otherwise the sign-in would fail with a 500
            # for as long as the cookie lives.
            request.session.delete("user_id")
            nil
          end
        end

        private def handle_connect(response, user, credential, provider, uid)
          user_id = user.id

          if credential && credential.user_id != user_id
            response.flash[:error] = "error-credential-conflict"
          elsif !credential
            result = link.call(user_id:, provider:, uid:)
            response.flash[:error] = "error-credential-conflict" if result.failure?
          end

          response.redirect_to "/@#{user.name}#tab-credentials"
        end

        private def login(request, response, user_id)
          request.session.clear
          request.session[:user_id] = user_id
          response.redirect_to routes.path(:root)
        end
      end
    end
  end
end
