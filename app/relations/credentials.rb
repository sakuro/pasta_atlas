# frozen_string_literal: true

module PastaAtlas
  module Relations
    class Credentials < PastaAtlas::DB::Relation
      schema :credentials, infer: true

      associations do
        belongs_to :users
      end
    end
  end
end
