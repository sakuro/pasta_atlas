# frozen_string_literal: true

require "tzinfo"

module PastaAtlas
  module Operations
    module Registrations
      class Create < PastaAtlas::Operation
        include Deps[
          "repos.credential_repo",
          "repos.user_profile_repo",
          "repos.user_preference_repo",
          "repos.user_repo",
          import_avatar: "operations.registrations.import_avatar"
        ]

        USERNAME_PATTERN = /\A[a-zA-Z0-9][a-zA-Z0-9_-]*[a-zA-Z0-9]\z|\A[a-zA-Z0-9]\z/
        private_constant :USERNAME_PATTERN
        RESERVED_NAMES = %w[guest api admin].freeze
        private_constant :RESERVED_NAMES

        def call(name:, timezone:, provider:, uid:, avatar_url:)
          step validate_name(name)
          step check_availability(name)
          tz = resolve_timezone(timezone)
          user = step register(name:, tz:, provider:, uid:)
          import_avatar_for(user, avatar_url)
          user
        end

        private def validate_name(name)
          return Failure([:invalid, "error-username-empty"]) if name.empty?
          return Failure([:invalid, "error-username-too-long"]) if name.length > 39
          return Failure([:invalid, "error-username-invalid-chars"]) unless name.match?(USERNAME_PATTERN)
          return Failure([:invalid, "error-username-reserved"]) if RESERVED_NAMES.include?(name)

          Success(nil)
        end

        private def check_availability(name)
          user_repo.find_by_name(name) ? Failure([:invalid, "error-username-taken"]) : Success(nil)
        end

        private def resolve_timezone(name)
          TZInfo::Timezone.get(name.to_s).name
        rescue TZInfo::InvalidTimezoneIdentifier, TZInfo::InvalidDataFile
          "UTC"
        end

        private def register(name:, tz:, provider:, uid:)
          user = nil
          user_repo.transaction do
            user = user_repo.create(name:)
            user_profile_repo.create(user_id: user.id)
            user_preference_repo.create(user_id: user.id, timezone: tz)
            credential_repo.create(user_id: user.id, provider:, uid:)
          end
          Success(user)
        end

        private def import_avatar_for(user, avatar_url)
          avatar_result = import_avatar.call(user_id: user.id, avatar_url:)
          user_profile_repo.update_avatar(user.id, avatar_s3_key: avatar_result.value!) if avatar_result.success?
        end
      end
    end
  end
end
