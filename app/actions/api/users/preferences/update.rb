# frozen_string_literal: true

module PastaAtlas
  module Actions
    module API
      module Users
        module Preferences
          class Update < PastaAtlas::Action
            include Deps[update_preferences: "operations.user.preferences.update"]

            params do
              required(:user_name).filled(:string)
              optional(:timezone).maybe(:string)
              optional(:locale).maybe(:string)
              optional(:relative_timestamps).maybe(:string)
            end

            def handle(request, response)
              result = update_preferences.call(
                user_id: current_user_id(request),
                user_name: request.params[:user_name],
                timezone: request.params[:timezone],
                locale: request.params[:locale],
                relative_timestamps: request.params[:relative_timestamps] == "true"
              )
              case result
              in Failure(Symbol => status)
                halt status
              in Success({locale:, **})
                # Rack::ICU4X::Locale middleware cannot access the database; keep the session in sync so locale detection reflects the updated preference immediately.
                request.session[:locale] = locale
                json_response(response, {locale:})
              end
            end
          end
        end
      end
    end
  end
end
