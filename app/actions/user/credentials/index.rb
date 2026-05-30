# frozen_string_literal: true

module PastaAtlas
  module Actions
    module User
      module Credentials
        class Index < PastaAtlas::Action
          include Deps[
            load_credentials: "operations.user.credentials.load",
            verify_ownership: "operations.user.verify_ownership"
          ]

          PROVIDERS = %w[discord github steam].freeze
          private_constant :PROVIDERS

          def handle(request, response)
            result = verify_ownership.call(
              user_id: current_user_id(request),
              user_name: request.params[:user_name]
            )
            case result
            in Failure(Symbol => status)
              halt status
            in Success(user)
              connected_providers = load_credentials.call(user_id: user.id, viewer_id: user.id).value!
              json_response(response, {
                providers: PROVIDERS,
                connected_providers:
              })
            end
          end
        end
      end
    end
  end
end
