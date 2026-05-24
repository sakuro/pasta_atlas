# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Auth
      class Failure < PastaAtlas::Action
        def handle(request, response)
          message = request.params[:message] || "unknown"
          response.redirect_to routes.path(:root, auth_error: message)
        end
      end
    end
  end
end
