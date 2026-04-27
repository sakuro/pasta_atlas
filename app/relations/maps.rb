# frozen_string_literal: true

module PastaAtlas
  module Relations
    class Maps < PastaAtlas::DB::Relation
      schema :maps, infer: true

      associations do
        belongs_to :user
        has_many :generations
      end
    end
  end
end
