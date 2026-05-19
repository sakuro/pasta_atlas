# frozen_string_literal: true

module PastaAtlas
  module Actions
    module User
      module Credentials
        class Destroy < PastaAtlas::Action
          include Deps["operations.user.credentials.unlink"]

          ALLOWED_PROVIDERS = %w[discord github steam].freeze
          private_constant :ALLOWED_PROVIDERS

          def handle(request, response)
            user_id = current_user_id(request)
            halt 403 unless user_id

            user = user_repo.find_by_id(user_id)
            halt 403 unless user.name == request.params[:user_name]
            halt 404 unless ALLOWED_PROVIDERS.include?(request.params[:provider])

            result = unlink.call(user_id:, provider: request.params[:provider])
            response.flash[:error] = "error-credential-last" if result.failure?

            response.redirect_to "/@#{user.name}/edit"
          end
        end
      end
    end
  end
end
