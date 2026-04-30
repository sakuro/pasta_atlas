# frozen_string_literal: true

module PastaAtlas
  module Operations
    module Maps
      class Show < PastaAtlas::Operation
        include Deps[
          "repos.map_repo",
          "repos.generation_repo",
          "repos.user_repo"
        ]

        def call(ulid:)
          map = step find_map(ulid)
          user = user_repo.find_by_id(map.user_id)
          generations = generation_repo.find_complete_by_map_id(map.id)
          {map:, user:, generations:}
        end

        private def find_map(ulid)
          map = map_repo.find_by_ulid(ulid)
          map ? Success(map) : Failure(:not_found)
        end
      end
    end
  end
end
