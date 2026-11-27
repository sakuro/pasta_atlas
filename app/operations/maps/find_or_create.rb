# frozen_string_literal: true

module PastaAtlas
  module Operations
    module Maps
      class FindOrCreate < PastaAtlas::Operation
        include Deps["repos.map_repo"]

        # A new map gets the display name; an existing map has it replaced only when
        # update_display_name_on_conflict is true.
        def call(user_id:, mapshot_map_id:, display_name:, update_display_name_on_conflict: true)
          map = map_repo.find_or_create_by_user_and_mapshot_id(user_id:, mapshot_map_id:, display_name:)
          return map if !update_display_name_on_conflict || map.display_name == display_name

          map_repo.update_display_name(id: map.id, display_name:)
          map_repo.find_by_id!(map.id)
        end
      end
    end
  end
end
