# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Spa
      class MapViewer < PastaAtlas::Action
        include Deps[
          "operations.user.find_by_name",
          find_map: "operations.maps.find_by_ulid"
        ]

        def handle(request, response)
          result = find_by_name.call(user_name: request.params[:user_name])
          case result
          in Failure(:not_found)
            response.status = 404
          in Success(user)
            map_result = find_map.call(ulid: request.params[:map_ulid], user_id: user.id)
            response.status = 404 if map_result.failure?
          end
        end
      end
    end
  end
end
