# frozen_string_literal: true

module PastaAtlas
  module Actions
    module User
      module Avatar
        class Update < PastaAtlas::Action
          include Deps[update_avatar: "operations.user.avatar.update"]

          def handle(request, response)
            result = update_avatar.call(
              user_id: current_user_id(request),
              user_name: request.params[:user_name],
              s3_key: request.params[:s3_key].to_s
            )
            case result
            in Failure(Symbol => status)
              halt status
            in Success
              response.status = :no_content
            end
          end
        end
      end
    end
  end
end
