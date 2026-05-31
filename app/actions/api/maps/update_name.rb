# frozen_string_literal: true

module PastaAtlas
  module Actions
    module API
      module Maps
        class UpdateName < PastaAtlas::Action
          include Deps[update_map_name: "operations.maps.update_name"]

          def handle(request, response)
            result = update_map_name.call(
              ulid: request.params[:ulid],
              name: request.params[:name].to_s.strip,
              current_user_id: current_user_id(request)
            )
            case result
            in Success(map)
              json_response(response, {display_name: map.display_name})
            in Failure(Symbol => status)
              halt status
            end
          end
        end
      end
    end
  end
end
