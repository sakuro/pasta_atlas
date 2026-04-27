# frozen_string_literal: true

module PastaAtlas
  module Relations
    class Maps < PastaAtlas::DB::Relation
      schema :maps, infer: true do
        associations do
          belongs_to :user
          has_many :generations
        end
      end

      def by_user_and_mapshot_id(user_id, mapshot_map_id)
        where(user_id:, mapshot_map_id:)
      end
    end
  end
end
