# frozen_string_literal: true

module PastaAtlas
  module Relations
    class Uploads < PastaAtlas::DB::Relation
      schema :uploads, infer: true

      associations do
        belongs_to :generations
      end
    end
  end
end
