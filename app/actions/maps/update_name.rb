# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Maps
      class UpdateName < PastaAtlas::Action
        include Deps[update_map_name: "operations.maps.update_name"]

        def handle(request, response)
          user_id = current_user_id(request)
          halt 401 unless user_id

          result = update_map_name.call(
            ulid: request.params[:ulid],
            name: request.params[:name].to_s.strip,
            current_user_id: user_id
          )
          case result
          in Success(map)
            json_response(response, {display_name: map.display_name})
          in Failure(:not_found)
            halt 404
          in Failure(:forbidden)
            halt 403
          end
        end
      end
    end
  end
end
