# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Profile
      class Edit < PastaAtlas::Action
        include Deps["repos.user_profile_repo"]

        def handle(request, response)
          user_id = current_user_id(request)
          halt 403 unless user_id
          halt 403 unless user_repo.find_by_id(user_id).name == request.params[:user_name]

          profile = user_profile_repo.find_by_user_id(user_id)
          response.render view, display_name: profile.display_name.to_s
        end
      end
    end
  end
end
