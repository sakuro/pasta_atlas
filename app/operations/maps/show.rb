# frozen_string_literal: true

module PastaAtlas
  module Operations
    module Maps
      class Show < PastaAtlas::Operation
        include Deps[
          "repos.generation_repo",
          "repos.map_repo",
          "repos.user_profile_repo",
          "repos.user_repo",
          "settings"
        ]

        def call(ulid:)
          map = step find_map(ulid)
          user = user_repo.find_by_id(map.user_id)
          profile = user_profile_repo.find_by_user_id(user.id)
          generations = generation_repo.find_complete_by_map_id(map.id)
          step check_has_generations(generations)
          latest_generation = generations.max_by(&:created_at)
          cloudfront_base_url = settings.cloudfront_base_url
          avatar_url = profile.avatar_s3_key ? "#{cloudfront_base_url}/#{profile.avatar_s3_key}" : nil
          user_info = Values::UserInfo[name: user.name, display_name: profile.display_name || user.name, avatar_url:]
          map_info = Values::MapInfo[
            ulid: map.ulid,
            display_name: map.display_name,
            user_info:,
            thumbnail_url: latest_generation.thumbnail_url(cloudfront_base_url),
            metadata_url: latest_generation.metadata_url(cloudfront_base_url),
            updated_at: latest_generation.created_at
          ]
          generation_list = generations.map {|g| {ulid: g.ulid, tick: g.tick, metadata_url: g.metadata_url(cloudfront_base_url)} }
          {map_info:, generations: generation_list}
        end

        private def find_map(ulid)
          map = map_repo.find_by_ulid(ulid)
          map ? Success(map) : Failure(:not_found)
        end

        private def check_has_generations(generations)
          generations.any? ? Success(generations) : Failure(:not_found)
        end
      end
    end
  end
end
