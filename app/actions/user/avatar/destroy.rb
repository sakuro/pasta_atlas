# frozen_string_literal: true

module PastaAtlas
  module Actions
    module User
      module Avatar
        class Destroy < PastaAtlas::Action
          include Deps[
            "repos.user_profile_repo",
            verify_ownership: "operations.user.verify_ownership"
          ]

          def handle(request, response)
            result = verify_ownership.call(
              user_id: current_user_id(request),
              user_name: request.params[:user_name]
            )
            case result
            in Failure(status)
              halt status
            in Success(user)
              user_profile_repo.clear_avatar(user.id)
              response.status = 204
            end
          end
        end
      end
    end
  end
end
