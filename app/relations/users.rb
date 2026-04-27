# frozen_string_literal: true

module PastaAtlas
  module Relations
    class Users < PastaAtlas::DB::Relation
      schema :users, infer: true

      associations do
        has_one :user_profiles
        has_many :credentials
        has_many :maps
      end
    end
  end
end
