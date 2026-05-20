# frozen_string_literal: true

module PastaAtlas
  module Actions
    module User
      module Avatar
        class Destroy < PastaAtlas::Action
          include Deps[destroy_avatar: "operations.user.avatar.destroy"]

          def handle(request, response)
            result = destroy_avatar.call(
              user_id: current_user_id(request),
              user_name: request.params[:user_name]
            )
            case result
            in Failure(Symbol => status)
              halt status
            in Success
              response.status = 204
            end
          end
        end
      end
    end
  end
end
