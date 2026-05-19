# frozen_string_literal: true

module PastaAtlas
  module Operations
    module Maps
      class ListRecentByUser < PastaAtlas::Operation
        include Deps["repos.generation_repo", "repos.map_repo", "settings"]

        LIMIT = 3
        private_constant :LIMIT

        def call(user_id:, user_info:)
          recent_maps = map_repo.list_with_complete_generation_by_user(user_id:, limit: LIMIT)
          map_ids = recent_maps.map(&:id)
          latest_generations = generation_repo.find_latest_complete_by_map_ids(map_ids)
          max_created_at_by_map_id = generation_repo.find_max_created_at_by_map_ids(map_ids)
          recent_maps.map {|m|
            g = latest_generations[m.id]
            thumbnail_url = g && "#{settings.cloudfront_base_url}/#{g.metadata_s3_key.sub("mapshot.json", "s1zoom_4/tile_0_0.jpg")}"
            metadata_url = g && "#{settings.cloudfront_base_url}/#{g.metadata_s3_key}"
            updated_at = max_created_at_by_map_id[m.id]
            Values::MapInfo[ulid: m.ulid, display_name: m.display_name, user_info:, thumbnail_url:, metadata_url:, updated_at:]
          }
        end
      end
    end
  end
end
