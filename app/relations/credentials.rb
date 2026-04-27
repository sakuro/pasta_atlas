# frozen_string_literal: true

module PastaAtlas
  module Relations
    class Credentials < PastaAtlas::DB::Relation
      schema :credentials, infer: true do
        associations do
          belongs_to :user
        end
      end
    end
  end
end
