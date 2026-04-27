# frozen_string_literal: true

module PastaAtlas
  module Operations
    module Maps
      class FindOrCreate < PastaAtlas::Operation
        include Deps["repos.map_repo"]

        def call(user_id:, mapshot_map_id:, savename: "", name: nil)
          map = map_repo.find_or_create_by_user_and_mapshot_id(
            user_id:,
            mapshot_map_id:,
            savename:,
            name:
          )
          Success(map)
        end
      end
    end
  end
end
