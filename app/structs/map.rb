# frozen_string_literal: true

module PastaAtlas
  module Structs
    class Map < PastaAtlas::DB::Struct
      def owned_by?(user) = user_id == user.id

      # Resolves: name → savename (if present) → mapshot_map_id
      def display_name
        return name if name && !name.empty?
        return savename unless savename.empty?

        mapshot_map_id
      end
    end
  end
end
