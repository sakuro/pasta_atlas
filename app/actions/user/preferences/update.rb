# frozen_string_literal: true

require "tzinfo"

module PastaAtlas
  module Actions
    module User
      module Preferences
        class Update < PastaAtlas::Action
          include Deps[
            "repos.user_preference_repo",
            verify_ownership: "operations.user.verify_ownership"
          ]

          SUPPORTED_LOCALES = PastaAtlas::I18n::SUPPORTED_LOCALES
          private_constant :SUPPORTED_LOCALES

          params do
            required(:user_name).filled(:string)
            optional(:timezone).maybe(:string)
            optional(:locale).maybe(:string)
          end

          def handle(request, response)
            result = verify_ownership.call(
              user_id: current_user_id(request),
              user_name: request.params[:user_name]
            )
            case result
            in Failure(status)
              halt status
            in Success(user)
              timezone = valid_timezone(request.params[:timezone])
              locale = valid_locale(request.params[:locale])
              user_preference_repo.update_preferences(user.id, timezone:, locale:)
              # Rack::ICU4X::Locale middleware cannot access the database; keep the session in sync so locale detection reflects the updated preference immediately.
              request.session[:locale] = locale
              response.redirect_to "/@#{user.name}"
            end
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
