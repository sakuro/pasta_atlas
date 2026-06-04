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
          updated_at = latest_generation.created_at
          thumbnail_url = latest_generation.thumbnail_url(settings.cloudfront_base_url)
          {map:, user:, profile:, generations:, updated_at:, thumbnail_url:}
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
