# frozen_string_literal: true

module PastaAtlas
  module Relations
    class Users < PastaAtlas::DB::Relation
      schema :users, infer: true do
        associations do
          has_one :user_profile
          has_one :user_preference
          has_many :credentials
          has_many :maps
        end
      end
    end
  end
end
