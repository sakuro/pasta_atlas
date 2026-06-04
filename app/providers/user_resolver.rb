# frozen_string_literal: true

module PastaAtlas
  module Providers
    class UserResolver
      include Deps["repos.user_repo", "system_users.guest"]

      def call(user_id)
        return guest unless user_id

        user_repo.find_by_id(user_id)
      rescue ROM::TupleCountMismatchError
        guest
      end
    end
  end
end
