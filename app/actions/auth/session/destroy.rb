# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Auth
      module Session
        class Destroy < PastaAtlas::Action
          def handle(request, response)
            request.session.clear
            response.redirect_to routes.path(:root)
          end
        end
      end
    end
  end
end
