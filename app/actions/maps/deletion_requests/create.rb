# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Maps
      module DeletionRequests
        class Create < PastaAtlas::Action
          include Deps[request_deletion: "operations.maps.request_deletion"]

          def handle(request, response)
            result = request_deletion.call(
              ulid: request.params[:ulid],
              current_user_id: current_user_id(request)
            )
            case result
            in Success(_)
              response.flash[:notice] = "map-deletion-requested"
              response.redirect_to "/"
            in Failure(Symbol => status)
              halt status
            end
          end
        end
      end
    end
  end
end
