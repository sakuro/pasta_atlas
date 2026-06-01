# frozen_string_literal: true

module PastaAtlas
  module Operations
    module Maps
      class FindByUlid < PastaAtlas::Operation
        include Deps["repos.map_repo"]

        def call(ulid:, user_id:)
          map = step find_map(ulid)
          step(map.user_id == user_id ? Success(map) : Failure(:not_found))
        end

        private def find_map(ulid)
          map = map_repo.find_by_ulid(ulid)
          map ? Success(map) : Failure(:not_found)
        end
      end
    end
  end
end
