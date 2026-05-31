# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Spa
      class Shell < PastaAtlas::Action
        def handle(_request, response)
          response.render(view)
        end
      end
    end
  end
end
