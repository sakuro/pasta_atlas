# frozen_string_literal: true

module PastaAtlas
  module Operations
    module User
      module Profile
        class Update < PastaAtlas::Operation
          include Deps[
            "operations.user.verify_ownership",
            "repos.user_profile_repo"
          ]

          DISPLAY_NAME_MAX_GRAPHEME_CLUSTERS = 30
          private_constant :DISPLAY_NAME_MAX_GRAPHEME_CLUSTERS

          def call(user_id:, user_name:, display_name:, avatar_s3_key:)
            user = step verify_ownership.call(user_id:, user_name:)
            step validate_display_name(display_name)
            user_profile_repo.update_profile(user.id, display_name: display_name.empty? ? nil : display_name)
            if !avatar_s3_key.empty? && avatar_s3_key.start_with?("#{user.name}/avatar/")
              user_profile_repo.update_avatar(user.id, avatar_s3_key:)
            end
            user
          end

          private def validate_display_name(name)
            return Success() if name.empty?
            return Failure([:invalid, "error-profile-display-name-too-long"]) if grapheme_clusters_exceed?(name, DISPLAY_NAME_MAX_GRAPHEME_CLUSTERS)
            return Failure([:invalid, "error-profile-display-name-invalid-chars"]) if name.match?(DISALLOWED_CHARS)

            Success()
          end
        end
      end
    end
  end
end
