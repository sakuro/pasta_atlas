# frozen_string_literal: true

module PastaAtlas
  module Operations
    module User
      module Avatar
        class Destroy < PastaAtlas::Operation
          include Deps[
            "repos.user_profile_repo",
            "operations.user.verify_ownership"
          ]

          def call(user_id:, user_name:)
            user = step verify_ownership.call(user_id:, user_name:)
            user_profile_repo.clear_avatar(user.id)
          end
        end
      end
    end
  end
end
