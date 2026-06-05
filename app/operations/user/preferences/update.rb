# frozen_string_literal: true

require "tzinfo"

module PastaAtlas
  module Operations
    module User
      module Preferences
        class Update < PastaAtlas::Operation
          include Deps[
            "locale.supported_locales",
            "repos.user_preference_repo"
          ]

          def call(user:, timezone:, locale:, relative_timestamps:)
            timezone = valid_timezone(timezone)
            locale = valid_locale(locale)
            user_preference_repo.update_preferences(user.id, timezone:, locale:, relative_timestamps:)
            {user:, locale:}
          end

          private def valid_timezone(name)
            return nil if name.nil? || name.empty?

            TZInfo::Timezone.get(name).name
          rescue TZInfo::InvalidTimezoneIdentifier, TZInfo::InvalidDataFile
            nil
          end

          private def valid_locale(value)
            return nil if value.nil? || value.empty?

            supported_locales.include?(value) ? value : nil
          end
        end
      end
    end
  end
end
