# frozen_string_literal: true

module PastaAtlas
  module Relations
    class Generations < PastaAtlas::DB::Relation
      schema :generations, infer: true

      associations do
        belongs_to :map
        has_one :upload
      end

      def by_map_and_unique_id(map_id, mapshot_unique_id)
        where(map_id:, mapshot_unique_id:)
      end
    end
  end
end
