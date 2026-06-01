# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Spa
      class NotFound < PastaAtlas::Action
        def handle(_request, response)
          response.status = 404
        end
      end
    end
  end
end
