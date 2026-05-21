# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Maps
      class Index < PastaAtlas::Action
        include Deps[list_maps: "operations.maps.list"]

        def handle(request, response)
          page = [Integer(request.params[:page] || 1, exception: false) || 1, 1].max
          case list_maps.call(page:)
          in Success(payload)
            response.render(view, **payload)
          end
        end
      end
    end
  end
end
