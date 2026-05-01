# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Auth
      module Registrations
        class New < PastaAtlas::Action
          def handle(request, response)
            pending = request.session[:pending_auth]
            halt 403 unless pending

            response.render view, suggested_name: pending["login"]
          end
        end
      end
    end
  end
end
