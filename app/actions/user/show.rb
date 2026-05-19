# frozen_string_literal: true

module PastaAtlas
  module Actions
    module User
      class Show < PastaAtlas::Action
        include Deps[
          "repos.generation_repo",
          "repos.map_repo",
          "settings",
          load_credentials: "operations.user.credentials.load",
          load_preferences: "operations.user.preferences.load",
          load_profile: "operations.user.profile.load"
        ]

        RECENT_MAPS_LIMIT = 3
        private_constant :RECENT_MAPS_LIMIT

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

          recent_maps = map_repo.list_with_complete_generation_by_user(user_id: user.id, limit: RECENT_MAPS_LIMIT)
          map_ids = recent_maps.map(&:id)
          latest_generations = generation_repo.find_latest_complete_by_map_ids(map_ids)
          max_created_at_by_map_id = generation_repo.find_max_created_at_by_map_ids(map_ids)
          recent_map_infos = recent_maps.map {|m|
            g = latest_generations[m.id]
            thumbnail_url = g && "#{settings.cloudfront_base_url}/#{g.metadata_s3_key.sub("mapshot.json", "s1zoom_4/tile_0_0.jpg")}"
            metadata_url = g && "#{settings.cloudfront_base_url}/#{g.metadata_s3_key}"
            updated_at = max_created_at_by_map_id[m.id]
            Values::MapInfo[ulid: m.ulid, display_name: m.display_name, user_info:, thumbnail_url:, metadata_url:, updated_at:]
          }

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
