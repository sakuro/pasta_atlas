# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Profile
      class Show < PastaAtlas::Action
        include Deps["repos.user_profile_repo"]

        def handle(request, response)
          user = user_repo.find_by_name(request.params[:user_name])
          halt 404 unless user

          profile = user_profile_repo.find_by_user_id(user.id)
          own_profile = current_user_id(request) == user.id

          response.render view, user_name: user.name, display_name: profile.display_name, own_profile:
        end
      end
    end
  end
end
