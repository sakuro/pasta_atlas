# frozen_string_literal: true

module PastaAtlas
  module Relations
    class UserProfiles < PastaAtlas::DB::Relation
      schema :user_profiles, infer: true do
        associations do
          belongs_to :user
        end
      end
    end
  end
end
