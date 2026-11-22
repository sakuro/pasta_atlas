# frozen_string_literal: true

module PastaAtlas
  module Operations
    module User
      module Avatar
        class Destroy < PastaAtlas::Operation
          include Deps[
            "repos.user_profile_repo",
            schedule_avatar_cleanup: "operations.user.avatar.schedule_cleanup"
          ]

          def call(user:)
            old_s3_key = user_profile_repo.find_by_user_id!(user.id).avatar_s3_key
            user_profile_repo.clear_avatar(user.id)
            schedule_avatar_cleanup.call(s3_key: old_s3_key) if old_s3_key
            user
          end
        end
      end
    end
  end
end
