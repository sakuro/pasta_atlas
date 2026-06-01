# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Spa
      class MapViewer < PastaAtlas::Action
        include Deps[find_map: "operations.maps.find_by_ulid"]

        def handle(request, response)
          result = find_map.call(ulid: request.params[:map_ulid])
          response.status = 404 if result.failure?
        end
      end
    end
  end
end
