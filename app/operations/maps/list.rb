# frozen_string_literal: true

module PastaAtlas
  module Operations
    module Maps
      class List < PastaAtlas::Operation
        include Deps["repos.map_repo", "repos.user_repo", "repos.generation_repo", "settings"]

        PER_PAGE = 20
        private_constant :PER_PAGE

        def call(page: 1)
          maps = map_repo.list_with_complete_generation(page:, per_page: PER_PAGE)
          total = map_repo.count_with_complete_generation

          user_ids = maps.map(&:user_id)
          user_ids.uniq!
          users_by_id = user_repo.find_by_ids(user_ids).to_h {|u| [u.id, u] }

          map_ids = maps.map(&:id)
          latest_generations = generation_repo.find_latest_complete_by_map_ids(map_ids)
          id_to_ulid = maps.to_h {|m| [m.id, m.ulid] }
          thumbnail_urls_by_map_ulid = latest_generations.to_h {|map_id, g|
            url = "#{settings.cloudfront_base_url}/#{g.metadata_s3_key.sub("mapshot.json", "s1zoom_4/tile_0_0.jpg")}"
            [id_to_ulid[map_id], url]
          }

          {maps:, users_by_id:, thumbnail_urls_by_map_ulid:, page:, per_page: PER_PAGE, total:}
        end
      end
    end
  end
end
