# frozen_string_literal: true

module PastaAtlas
  module Actions
    module User
      class Show < PastaAtlas::Action
        include Deps[
          find_by_name: "operations.user.find_by_name",
          load_profile: "operations.user.profile.load"
        ]

        def handle(request, response)
          result = find_by_name.call(user_name: request.params[:user_name])
          case result
          in Failure(Symbol => status)
            halt status
          in Success(user)
            halt :not_found if user.guest?

            is_owner = current_user_id(request) == user.id
            profile_data = load_profile.call(user_id: user.id).value!

            response.render view,
              user_name: user.name,
              display_name: profile_data[:display_name],
              avatar_url: profile_data[:avatar_url],
              is_owner:
          end
        end
      end
    end
  end
end
