# frozen_string_literal: true

module PastaAtlas
  module Operations
    module Maps
      class FindOrCreate < PastaAtlas::Operation
        include Deps["repos.map_repo"]

        # The name is set on a map that has none and, when update_name_on_conflict is true,
        # replaced on a map that has one. The savename is kept as it was at the first upload.
        def call(user_id:, mapshot_map_id:, savename: "", name: nil, update_name_on_conflict: true)
          map = map_repo.find_or_create_by_user_and_mapshot_id(user_id:, mapshot_map_id:, savename:)
          return map unless rename?(map, name, update_name_on_conflict)

          map_repo.update_name(id: map.id, name:)
          map_repo.find_by_id!(map.id)
        end

        private def rename?(map, name, update_name_on_conflict)
          return false unless name

          update_name_on_conflict || map.name.nil?
        end
      end
    end
  end
end
