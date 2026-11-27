# frozen_string_literal: true

module PastaAtlas
  module Structs
    class Map < PastaAtlas::DB::Struct
      def owned_by?(user) = user_id == user.id
    end
  end
end
