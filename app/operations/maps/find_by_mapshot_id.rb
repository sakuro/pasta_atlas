# frozen_string_literal: true

module PastaAtlas
  module Operations
    module Maps
      class FindByMapshotId < PastaAtlas::Operation
        include Deps["repos.map_repo"]

        def call(user_id:, mapshot_map_id:)
          map = map_repo.find_by_user_and_mapshot_id(user_id:, mapshot_map_id:)
          step(map ? Success(map) : Failure(:not_found))
        end
      end
    end
  end
end
