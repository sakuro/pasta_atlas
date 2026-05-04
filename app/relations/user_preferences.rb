# frozen_string_literal: true

module PastaAtlas
  module Relations
    class UserPreferences < PastaAtlas::DB::Relation
      schema :user_preferences, infer: true do
        associations do
          belongs_to :user
        end
      end
    end
  end
end
