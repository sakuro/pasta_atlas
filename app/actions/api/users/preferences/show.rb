# frozen_string_literal: true

require "tzinfo"

module PastaAtlas
  module Actions
    module API
      module Users
        module Preferences
          class Show < PastaAtlas::Action
            include Deps[
              "operations.user.verify_ownership",
              load_preferences: "operations.user.preferences.load"
            ]

            def handle(request, response)
              result = verify_ownership.call(
                user_id: current_user_id(request),
                user_name: request.params[:user_name]
              )
              case result
              in Failure(Symbol => status)
                halt status
              in Success(user)
                preference = load_preferences.call(user_id: user.id, viewer_id: user.id).value!
                json_response(response, {
                  timezone: preference.timezone,
                  timezone_identifiers: TZInfo::Timezone.all_identifiers,
                  locale: preference.locale,
                  supported_locales: PastaAtlas::I18n::SUPPORTED_LOCALES,
                  relative_timestamps: preference.relative_timestamps
                })
              end
            end
          end
        end
      end
    end
  end
end
