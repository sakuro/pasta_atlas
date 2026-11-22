# frozen_string_literal: true

module PastaAtlas
  module Operations
    module User
      module Avatar
        class Update < PastaAtlas::Operation
          include Deps[
            "repos.user_profile_repo",
            schedule_avatar_cleanup: "operations.user.avatar.schedule_cleanup",
            verify_avatar_upload: "operations.user.avatar.verify_upload"
          ]

          def call(user:, s3_key:)
            step verify_avatar_upload.call(user:, s3_key:)
            old_s3_key = user_profile_repo.find_by_user_id!(user.id).avatar_s3_key
            user_profile_repo.update_avatar(user.id, avatar_s3_key: s3_key)
            schedule_avatar_cleanup.call(s3_key: old_s3_key) if old_s3_key
            user
          end
        end
      end
    end
  end
end
