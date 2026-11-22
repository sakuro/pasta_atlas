# frozen_string_literal: true

module PastaAtlas
  module Operations
    module User
      module Profile
        class Update < PastaAtlas::Operation
          include Deps[
            "repos.user_profile_repo",
            schedule_avatar_cleanup: "operations.user.avatar.schedule_cleanup"
          ]

          DISPLAY_NAME_MAX_GRAPHEME_CLUSTERS = 30
          private_constant :DISPLAY_NAME_MAX_GRAPHEME_CLUSTERS

          def call(user:, display_name:, avatar_s3_key:)
            step validate_display_name(display_name)
            user_profile_repo.update_profile(user.id, display_name: display_name.empty? ? nil : display_name)
            replace_avatar(user, avatar_s3_key) if avatar_s3_key.start_with?("#{user.name}/avatar/")
            user
          end

          private def validate_display_name(name)
            return Success() if name.empty?
            return Failure([:invalid, "error-profile-display-name-too-long"]) if grapheme_clusters_exceed?(name, DISPLAY_NAME_MAX_GRAPHEME_CLUSTERS)
            return Failure([:invalid, "error-profile-display-name-invalid-chars"]) if name.match?(DISALLOWED_CHARS)

            Success()
          end

          private def replace_avatar(user, s3_key)
            old_s3_key = user_profile_repo.find_by_user_id!(user.id).avatar_s3_key
            user_profile_repo.update_avatar(user.id, avatar_s3_key: s3_key)
            # Re-applying the current key must not queue it: that would delete the avatar in use.
            schedule_avatar_cleanup.call(s3_key: old_s3_key) if old_s3_key && old_s3_key != s3_key
          end
        end
      end
    end
  end
end
