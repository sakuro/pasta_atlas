# frozen_string_literal: true

module PastaAtlas
  module Operations
    module Maps
      class List < PastaAtlas::Operation
        include Deps["repos.map_repo", "repos.user_repo", "repos.user_profile_repo", "repos.generation_repo", "settings"]

        PER_PAGE = 20
        private_constant :PER_PAGE

        def call(page: 1)
          maps = map_repo.list_with_complete_generation(page:, per_page: PER_PAGE)
          total = map_repo.count_with_complete_generation

          user_ids = maps.map(&:user_id)
          user_ids.uniq!
          users_by_id = user_repo.find_by_ids(user_ids).to_h {|u| [u.id, u] }
          profiles_by_user_id = user_profile_repo.find_by_user_ids(user_ids).to_h {|p| [p.user_id, p] }
          user_infos_by_user_id = users_by_id.transform_values {|u|
            profile = profiles_by_user_id[u.id]
            avatar_url = profile.avatar_s3_key ? "#{settings.cloudfront_base_url}/#{profile.avatar_s3_key}" : nil
            Values::UserInfo[name: u.name, display_name: profile.display_name || u.name, avatar_url:]
          }

          map_ids = maps.map(&:id)
          latest_generations = generation_repo.find_latest_complete_by_map_ids(map_ids)
          max_created_at_by_map_id = generation_repo.find_max_created_at_by_map_ids(map_ids)
          map_infos_by_ulid = maps.to_h {|m|
            g = latest_generations[m.id]
            thumbnail_url = g && "#{settings.cloudfront_base_url}/#{g.metadata_s3_key.sub("mapshot.json", "s1zoom_4/tile_0_0.jpg")}"
            metadata_url = g && "#{settings.cloudfront_base_url}/#{g.metadata_s3_key}"
            updated_at = max_created_at_by_map_id[m.id]
            [m.ulid, Values::MapInfo[thumbnail_url:, metadata_url:, updated_at:]]
          }

          {maps:, user_infos_by_user_id:, map_infos_by_ulid:, page:, per_page: PER_PAGE, total:}
        end
      end
    end
  end
end
