# frozen_string_literal: true

module PastaAtlas
  module Actions
    module User
      module Avatar
        class Update < PastaAtlas::Action
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
              s3_key = request.params[:s3_key].to_s
              halt 422 unless s3_key.start_with?("avatars/#{user.id}/")

              user_profile_repo.update_avatar(user.id, avatar_s3_key: s3_key)
              response.status = 204
            end
          end
        end
      end
    end
  end
end
