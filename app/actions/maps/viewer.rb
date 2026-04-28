# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Maps
      class Viewer < PastaAtlas::Action
        include Deps[show_map: "operations.maps.show"]

        def handle(request, response)
          ulid = request.params[:ulid]
          case show_map.call(ulid:)
          in Success({map:, user_profile:, generations:})
            response.render(view, ulid: map.ulid, display_name: map.display_name)
          in Failure(:not_found)
            response.status = 404
          end
        end
      end
    end
  end
end
