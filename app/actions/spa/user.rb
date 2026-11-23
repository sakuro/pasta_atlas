# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Spa
      class User < PastaAtlas::Action
        include Deps["operations.user.find_by_name"]

        def handle(request, response)
          result = find_by_name.call(user_name: request.params[:user_name])
          # A system user has no page, so it is answered as if it did not exist.
          response.status = 404 unless result.value_or(nil)&.public_profile?
        end
      end
    end
  end
end
