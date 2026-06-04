# frozen_string_literal: true

module PastaAtlas
  module Operations
    module Maps
      class List < PastaAtlas::Operation
        include Deps["repos.generation_repo", "repos.map_repo", "repos.user_profile_repo", "repos.user_repo", "settings"]

        PER_PAGE = 20
        private_constant :PER_PAGE

        def call(page: 1)
          maps = map_repo.list_with_complete_generation(page:, per_page: PER_PAGE)
          total = map_repo.count_with_complete_generation

          user_ids = maps.map(&:user_id)
          user_ids.uniq!
          users_by_id = user_repo.find_by_ids(user_ids).to_h {|u| [u.id, u] }
          profiles_by_user_id = user_profile_repo.find_by_user_ids(user_ids).to_h {|p| [p.user_id, p] }

          map_ids = maps.map(&:id)
          latest_generations = generation_repo.find_latest_complete_by_map_ids(map_ids)
          max_created_at_by_map_id = generation_repo.find_max_created_at_by_map_ids(map_ids)

          map_infos = maps.map {|m|
            user = users_by_id[m.user_id]
            profile = profiles_by_user_id[m.user_id]
            avatar_url = profile.avatar_s3_key ? "#{settings.cloudfront_base_url}/#{profile.avatar_s3_key}" : nil
            user_info = Values::UserInfo[name: user.name, display_name: profile.display_name || user.name, avatar_url:]

            g = latest_generations[m.id]
            thumbnail_url = g&.thumbnail_url(settings.cloudfront_base_url)
            metadata_url = g&.metadata_url(settings.cloudfront_base_url)
            updated_at = max_created_at_by_map_id[m.id]

            Values::MapInfo[ulid: m.ulid, display_name: m.display_name, user_info:, thumbnail_url:, metadata_url:, updated_at:]
          }

          {map_infos:, page:, per_page: PER_PAGE, total:}
        end
      end
    end
  end
end
