# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Spa
      class Forbidden < PastaAtlas::Action
        def handle(_, response)
          response.status = 403
        end
      end
    end
  end
end
