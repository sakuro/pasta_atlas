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
          map = map_repo.find_by_ulid(ulid)
          return Failure(:not_found) unless map

          user_profile = user_profile_repo.find_by_user_id(map.user_id)
          generations = generation_repo.find_complete_by_map_id(map.id)

          Success({map:, user_profile:, generations:})
        end
      end
    end
  end
end
