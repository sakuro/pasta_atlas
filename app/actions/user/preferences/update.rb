# frozen_string_literal: true

require "tzinfo"

module PastaAtlas
  module Actions
    module User
      module Preferences
        class Update < PastaAtlas::Action
          include Deps["repos.user_preference_repo"]

          SUPPORTED_LOCALES = PastaAtlas::I18n::SUPPORTED_LOCALES
          private_constant :SUPPORTED_LOCALES

          params do
            required(:user_name).filled(:string)
            optional(:timezone).maybe(:string)
            optional(:locale).maybe(:string)
          end

          def handle(request, response)
            user_id = current_user_id(request)
            halt 403 unless user_id

            user_name = request.params[:user_name]
            halt 403 unless user_repo.find_by_id(user_id).name == user_name

            timezone = valid_timezone(request.params[:timezone])
            locale = valid_locale(request.params[:locale])
            user_preference_repo.update_preferences(user_id, timezone:, locale:)
            # Rack::ICU4X::Locale middleware cannot access the database; keep the session in sync so locale detection reflects the updated preference immediately.
            request.session[:locale] = locale
            response.redirect_to "/@#{user_name}"
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
