# frozen_string_literal: true

module PastaAtlas
  module Actions
    module User
      class Show < PastaAtlas::Action
        include Deps[
          list_recent_maps: "operations.maps.list_recent_by_user",
          load_credentials: "operations.user.credentials.load",
          load_preferences: "operations.user.preferences.load",
          load_profile: "operations.user.profile.load"
        ]

        def handle(request, response)
          user = user_repo.find_by_name(request.params[:user_name])
          halt 404 unless user

          viewer_id = current_user_id(request)
          profile_data = load_profile.call(user_id: user.id).value!
          preference = load_preferences.call(user_id: user.id, viewer_id:).value_or(nil)
          connected_providers = load_credentials.call(user_id: user.id, viewer_id:).value_or(nil)

          own_profile = viewer_id == user.id
          avatar_url = profile_data[:avatar_url]
          user_info = Values::UserInfo[name: user.name, display_name: profile_data[:display_name] || user.name, avatar_url:]
          recent_map_infos = list_recent_maps.call(user_id: user.id, user_info:).value!

          response.render view,
            user_name: user.name,
            display_name: profile_data[:display_name],
            own_profile:,
            preference:,
            connected_providers:,
            avatar_url:,
            recent_map_infos:
        end
      end
    end
  end
end
