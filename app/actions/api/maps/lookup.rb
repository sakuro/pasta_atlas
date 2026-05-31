# frozen_string_literal: true

module PastaAtlas
  module Actions
    module API
      module Maps
        class Lookup < PastaAtlas::Action
          include Deps[find_map: "operations.maps.find_by_mapshot_id"]

          def handle(request, response)
            result = find_map.call(
              user_id: current_user_or_guest_id(request),
              mapshot_map_id: request.params[:mapshot_map_id]
            )

            case result
            in Success(map)
              json_response(response, {name: map.name})
            in Failure(:not_found)
              halt :not_found
            end
          end
        end
      end
    end
  end
end
