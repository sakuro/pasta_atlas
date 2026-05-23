# frozen_string_literal: true

require "tzinfo"

module PastaAtlas
  module Operations
    module User
      module Preferences
        class Update < PastaAtlas::Operation
          SUPPORTED_LOCALES = PastaAtlas::I18n::SUPPORTED_LOCALES
          private_constant :SUPPORTED_LOCALES

          include Deps[
            "repos.user_preference_repo",
            "operations.user.verify_ownership"
          ]

          def call(user_id:, user_name:, timezone:, locale:, relative_timestamps:)
            user = step verify_ownership.call(user_id:, user_name:)
            timezone = valid_timezone(timezone)
            locale = valid_locale(locale)
            user_preference_repo.update_preferences(user.id, timezone:, locale:, relative_timestamps:)
            {user:, locale:}
          end

          private def valid_timezone(name)
            TZInfo::Timezone.get(name.to_s).name
          rescue TZInfo::InvalidTimezoneIdentifier, TZInfo::InvalidDataFile
            "UTC"
          end

          private def valid_locale(value)
            return nil if value.nil? || value.empty?

            SUPPORTED_LOCALES.include?(value) ? value : nil
          end
        end
      end
    end
  end
end
