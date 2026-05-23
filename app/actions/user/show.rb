# frozen_string_literal: true

module PastaAtlas
  module Actions
    module User
      class Show < PastaAtlas::Action
        include Deps[
          "operations.user.find_by_name",
          "routes",
          list_recent_maps: "operations.maps.list_recent_by_user",
          load_profile: "operations.user.profile.load"
        ]

        def handle(request, response)
          result = find_by_name.call(user_name: request.params[:user_name])
          case result
          in Failure(Symbol => status)
            halt status
          in Success(user)
            halt :not_found if user.guest?

            if current_user_id(request) == user.id
              response.redirect_to routes.path(:edit_user, user_name: user.name)
              return
            end

            profile_data = load_profile.call(user_id: user.id).value!
            avatar_url = profile_data[:avatar_url]
            user_info = Values::UserInfo[name: user.name, display_name: profile_data[:display_name] || user.name, avatar_url:]
            recent_map_infos = list_recent_maps.call(user_id: user.id, user_info:).value!

            response.render view,
              user_name: user.name,
              display_name: profile_data[:display_name],
              avatar_url:,
              recent_map_infos:
          end
        end
      end
    end
  end
end
