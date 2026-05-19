# frozen_string_literal: true

module PastaAtlas
  module Actions
    module User
      module Credentials
        class Destroy < PastaAtlas::Action
          include Deps[
            "operations.user.credentials.unlink",
            "operations.user.verify_ownership"
          ]

          ALLOWED_PROVIDERS = %w[discord github steam].freeze
          private_constant :ALLOWED_PROVIDERS

          def handle(request, response)
            result = verify_ownership.call(
              user_id: current_user_id(request),
              user_name: request.params[:user_name]
            )
            case result
            in Failure(status)
              halt status
            in Success(user)
              halt 404 unless ALLOWED_PROVIDERS.include?(request.params[:provider])

              unlink_result = unlink.call(user_id: user.id, provider: request.params[:provider])
              response.flash[:error] = "error-credential-last" if unlink_result.failure?

              response.redirect_to "/@#{user.name}/edit"
            end
          end
        end
      end
    end
  end
end
