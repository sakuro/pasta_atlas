# frozen_string_literal: true

module PastaAtlas
  module Operations
    module User
      module Profile
        class Update < PastaAtlas::Operation
          include Deps[
            "repos.user_profile_repo",
            schedule_avatar_cleanup: "operations.user.avatar.schedule_cleanup",
            verify_avatar_upload: "operations.user.avatar.verify_upload"
          ]

          DISPLAY_NAME_MAX_GRAPHEME_CLUSTERS = 30
          private_constant :DISPLAY_NAME_MAX_GRAPHEME_CLUSTERS

          def call(user:, display_name:, avatar_s3_key:)
            step validate_display_name(display_name)
            # Verified before anything is written, so that a rejected avatar does not leave the display name changed.
            step verify_avatar(user, avatar_s3_key)
            user_profile_repo.update_profile(user.id, display_name: display_name.empty? ? nil : display_name)
            replace_avatar(user, avatar_s3_key) unless avatar_s3_key.empty?
            user
          end

          private def validate_display_name(name)
            return Success() if name.empty?
            return Failure([:invalid, "error-profile-display-name-too-long"]) if grapheme_clusters_exceed?(name, DISPLAY_NAME_MAX_GRAPHEME_CLUSTERS)
            return Failure([:invalid, "error-profile-display-name-invalid-chars"]) if name.match?(DISALLOWED_CHARS)

            Success()
          end

          private def verify_avatar(user, s3_key)
            return Success() if s3_key.empty?

            # The client reads the error body of this endpoint, so a rejected avatar carries a message like the display name does.
            verify_avatar_upload.call(user:, s3_key:).or do |failure|
              failure == :unprocessable_entity ? Failure([:invalid, "error-profile-avatar-invalid"]) : Failure(failure)
            end
          end

          private def replace_avatar(user, s3_key)
            old_s3_key = user_profile_repo.find_by_user_id!(user.id).avatar_s3_key
            user_profile_repo.update_avatar(user.id, avatar_s3_key: s3_key)
            schedule_avatar_cleanup.call(s3_key: old_s3_key) if old_s3_key
          end
        end
      end
    end
  end
end
