# frozen_string_literal: true

module PastaAtlas
  module Actions
    module User
      class Show < PastaAtlas::Action
        include Deps["repos.user_profile_repo", "repos.user_preference_repo", "repos.credential_repo", "repos.map_repo", "repos.generation_repo", "settings"]

        RECENT_MAPS_LIMIT = 3
        private_constant :RECENT_MAPS_LIMIT

        def handle(request, response)
          user = user_repo.find_by_name(request.params[:user_name])
          halt 404 unless user

          profile = user_profile_repo.find_by_user_id(user.id)
          own_profile = current_user_id(request) == user.id
          preference = own_profile ? user_preference_repo.find_by_user_id(user.id) : nil
          connected_providers = own_profile ? credential_repo.find_by_user_id(user.id).map(&:provider).sort! : nil

          recent_maps = map_repo.list_with_complete_generation_by_user(user_id: user.id, limit: RECENT_MAPS_LIMIT)
          map_ids = recent_maps.map(&:id)
          latest_generations = generation_repo.find_latest_complete_by_map_ids(map_ids)
          id_to_ulid = recent_maps.to_h {|m| [m.id, m.ulid] }
          thumbnail_urls_by_map_ulid = latest_generations.to_h {|map_id, g|
            url = "#{settings.cloudfront_base_url}/#{g.metadata_s3_key.sub("mapshot.json", "s1zoom_4/tile_0_0.jpg")}"
            [id_to_ulid[map_id], url]
          }
          metadata_urls_by_map_ulid = latest_generations.to_h {|map_id, g|
            [id_to_ulid[map_id], "#{settings.cloudfront_base_url}/#{g.metadata_s3_key}"]
          }

          avatar_url = profile.avatar_s3_key ? "#{settings.cloudfront_base_url}/#{profile.avatar_s3_key}" : nil

          max_created_at_by_map_id = generation_repo.find_max_created_at_by_map_ids(map_ids)
          updated_at_by_map_ulid = max_created_at_by_map_id.to_h {|map_id, ts| [id_to_ulid[map_id], ts] }

          response.render view,
            user_name: user.name,
            display_name: profile.display_name,
            own_profile:,
            preference:,
            connected_providers:,
            avatar_url:,
            recent_maps:,
            thumbnail_urls_by_map_ulid:,
            metadata_urls_by_map_ulid:,
            updated_at_by_map_ulid:
        end
      end
    end
  end
end
