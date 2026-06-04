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
            in Success({map:, owner:, updated_at:, generations:})
              json_response(response, {
                ulid: map.ulid,
                display_name: map.display_name,
                owner:,
                updated_at: updated_at&.iso8601,
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
