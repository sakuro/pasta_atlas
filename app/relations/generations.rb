# frozen_string_literal: true

module PastaAtlas
  module Relations
    class Generations < PastaAtlas::DB::Relation
      schema :generations, infer: true

      associations do
        belongs_to :maps
        has_one :uploads
      end
    end
  end
end
