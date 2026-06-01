# frozen_string_literal: true

module PastaAtlas
  module Operations
    module Maps
      class FindByUlid < PastaAtlas::Operation
        include Deps["repos.map_repo"]

        def call(ulid:)
          map = map_repo.find_by_ulid(ulid)
          step(map ? Success(map) : Failure(:not_found))
        end
      end
    end
  end
end
