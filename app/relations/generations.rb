# frozen_string_literal: true

module PastaAtlas
  module Relations
    class Generations < PastaAtlas::DB::Relation
      schema :generations, infer: true

      associations do
        belongs_to :map
        has_one :upload
      end
    end
  end
end
