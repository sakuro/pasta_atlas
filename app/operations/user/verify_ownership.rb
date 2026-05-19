# frozen_string_literal: true

module PastaAtlas
  module Operations
    module User
      class VerifyOwnership < PastaAtlas::Operation
        include Deps["repos.user_repo"]

        def call(user_id:, user_name:)
          user_id = step require_authentication(user_id)
          user = step find_user(user_id)
          step check_ownership(user, user_name)
        end

        private def require_authentication(user_id)
          user_id ? Success(user_id) : Failure(:forbidden)
        end

        private def find_user(user_id)
          Success(user_repo.find_by_id(user_id))
        end

        private def check_ownership(user, user_name)
          user.name == user_name ? Success(user) : Failure(:forbidden)
        end
      end
    end
  end
end
