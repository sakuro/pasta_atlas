# frozen_string_literal: true

module PastaAtlas
  module Actions
    module User
      module Avatar
        class Destroy < PastaAtlas::Action
          include Deps["repos.user_profile_repo"]

          def handle(request, response)
            user_id = current_user_id(request)
            halt 403 unless user_id
            halt 403 unless user_repo.find_by_id(user_id).name == request.params[:user_name]

            user_profile_repo.clear_avatar(user_id)
            response.status = 204
          end
        end
      end
    end
  end
end
