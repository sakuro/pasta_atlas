# frozen_string_literal: true

module PastaAtlas
  module Operations
    module Maps
      class ListRecentByUser < PastaAtlas::Operation
        include Deps["repos.generation_repo", "repos.map_repo", "repos.user_profile_repo", "repos.user_repo", "settings"]

        LIMIT = 3
        private_constant :LIMIT

        def call(user_id:)
          user = user_repo.find_by_id(user_id)
          profile = user_profile_repo.find_by_user_id(user_id)
          avatar_url = profile.avatar_s3_key ? "#{settings.cloudfront_base_url}/#{profile.avatar_s3_key}" : nil
          user_info = Values::UserInfo[name: user.name, display_name: profile.display_name || user.name, avatar_url:]

          recent_maps = map_repo.list_with_complete_generation_by_user(user_id:, limit: LIMIT)
          map_ids = recent_maps.map(&:id)
          latest_generations = generation_repo.find_latest_complete_by_map_ids(map_ids)
          max_created_at_by_map_id = generation_repo.find_max_created_at_by_map_ids(map_ids)
          recent_maps.map {|m|
            g = latest_generations[m.id]
            thumbnail_url = g&.thumbnail_url(settings.cloudfront_base_url)
            metadata_url = g&.metadata_url(settings.cloudfront_base_url)
            updated_at = max_created_at_by_map_id[m.id]
            Values::MapInfo[ulid: m.ulid, display_name: m.display_name, user_info:, thumbnail_url:, metadata_url:, updated_at:]
          }
        end
      end
    end
  end
end
