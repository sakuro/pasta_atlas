# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Spa
      class User < PastaAtlas::Action
        include Deps["operations.user.find_by_name"]

        def handle(request, response)
          result = find_by_name.call(user_name: request.params[:user_name])
          case result
          in Failure(:not_found)
            response.status = 404
          in Success(user) if !user.has_public_profile?
            response.status = 403
          in Success
            # 200 - default
          end
        end
      end
    end
  end
end
