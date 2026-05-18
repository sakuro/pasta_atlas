# frozen_string_literal: true

module PastaAtlas
  module Actions
    module User
      module Avatar
        class Update < PastaAtlas::Action
          include Deps["repos.user_profile_repo"]

          def handle(request, response)
            user_id = current_user_id(request)
            halt 403 unless user_id
            halt 403 unless user_repo.find_by_id(user_id).name == request.params[:user_name]

            s3_key = request.params[:s3_key].to_s
            halt 422 unless s3_key.start_with?("avatars/#{user_id}/")

            user_profile_repo.update_avatar(user_id, avatar_s3_key: s3_key)
            response.status = 204
          end
        end
      end
    end
  end
end
