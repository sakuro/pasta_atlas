# frozen_string_literal: true

require "ulid"

module PastaAtlas
  module Repos
    class MapRepo < PastaAtlas::DB::Repo
      def find_by_id(id) = root.where(id:).one

      def find_or_create_by_user_and_mapshot_id(user_id:, mapshot_map_id:, savename: "", name: nil)
        root.dataset.insert_conflict(target: %i[user_id mapshot_map_id]).insert(
          user_id:, mapshot_map_id:, ulid: ULID.generate, savename:, name:
        )
        root.by_user_and_mapshot_id(user_id, mapshot_map_id).one!
      end
    end
  end
end
