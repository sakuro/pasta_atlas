# frozen_string_literal: true

module PastaAtlas
  module Relations
    class UserProfiles < PastaAtlas::DB::Relation
      schema :user_profiles, infer: true

      associations do
        belongs_to :users
      end
    end
  end
end
