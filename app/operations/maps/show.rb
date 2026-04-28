# frozen_string_literal: true

module PastaAtlas
  module Operations
    module Maps
      class Show < PastaAtlas::Operation
        include Deps[
          "repos.map_repo",
          "repos.generation_repo",
          "repos.user_profile_repo"
        ]

        def call(ulid:)
          map = step find_map(ulid)
          user_profile = step find_user_profile(map.user_id)
          generations = generation_repo.find_complete_by_map_id(map.id)
          {map:, user_profile:, generations:}
        end

        private def find_map(ulid)
          map = map_repo.find_by_ulid(ulid)
          map ? Success(map) : Failure(:not_found)
        end

        private def find_user_profile(user_id)
          profile = user_profile_repo.find_by_user_id(user_id)
          profile ? Success(profile) : Failure(:not_found)
        end
      end
    end
  end
end
