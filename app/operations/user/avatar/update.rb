# frozen_string_literal: true

module PastaAtlas
  module Operations
    module User
      module Avatar
        class Update < PastaAtlas::Operation
          include Deps[
            "repos.user_profile_repo",
            schedule_avatar_cleanup: "operations.user.avatar.schedule_cleanup"
          ]

          def call(user:, s3_key:)
            step validate_s3_key(s3_key, user.name)
            old_s3_key = user_profile_repo.find_by_user_id!(user.id).avatar_s3_key
            user_profile_repo.update_avatar(user.id, avatar_s3_key: s3_key)
            # Re-applying the current key must not queue it: that would delete the avatar in use.
            schedule_avatar_cleanup.call(s3_key: old_s3_key) if old_s3_key && old_s3_key != s3_key
            user
          end

          private def validate_s3_key(s3_key, user_name)
            s3_key.start_with?("#{user_name}/avatar/") ? Success(s3_key) : Failure(:unprocessable_entity)
          end
        end
      end
    end
  end
end
