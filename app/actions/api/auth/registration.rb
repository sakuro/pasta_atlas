# frozen_string_literal: true

module PastaAtlas
  module Actions
    module API
      module Auth
        class Registration < PastaAtlas::Action
          def handle(request, response)
            pending = request.session[:pending_auth]
            halt :unauthorized unless pending

            json_response(response, {
              provider: pending["provider"],
              login_name: pending["login"]
            })
          end
        end
      end
    end
  end
end
