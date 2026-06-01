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
            case find_map.call(ulid: request.params[:map_ulid])
            in Failure(:not_found)
              response.status = 404
            in Success(map) if map.user_id != user.id
              response.status = 404
            in Success
              # 200 - default
            end
          end
        end
      end
    end
  end
end
