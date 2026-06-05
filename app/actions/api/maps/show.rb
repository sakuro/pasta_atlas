# frozen_string_literal: true

module PastaAtlas
  module Actions
    module API
      module Maps
        class Show < PastaAtlas::Action
          include Deps[show_map: "operations.maps.show"]

          def handle(request, response)
            result = show_map.call(ulid: request.params[:ulid])
            case result
            in Success({map_info:, generations:})
              json_response(response, {
                ulid: map_info.ulid,
                display_name: map_info.display_name,
                owner: map_info.user_info.to_h,
                updated_at: map_info.updated_at&.iso8601,
                generations:
              })
            in Failure(Symbol => status)
              halt status
            end
          end
        end
      end
    end
  end
end
