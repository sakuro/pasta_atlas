# frozen_string_literal: true

module PastaAtlas
  module Operations
    module User
      module Avatar
        class Update < PastaAtlas::Operation
          include Deps[
            "repos.user_profile_repo",
            verify_ownership: "operations.user.verify_ownership"
          ]

          def call(user_id:, user_name:, s3_key:)
            user = step verify_ownership.call(user_id:, user_name:)
            step validate_s3_key(s3_key, user.id)
            user_profile_repo.update_avatar(user.id, avatar_s3_key: s3_key)
          end

          private def validate_s3_key(s3_key, user_id)
            s3_key.start_with?("avatars/#{user_id}/") ? Success(s3_key) : Failure(:unprocessable_entity)
          end
        end
      end
    end
  end
end
