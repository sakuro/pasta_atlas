# frozen_string_literal: true

module PastaAtlas
  module Actions
    module API
      module Users
        module Preferences
          class Update < PastaAtlas::Action
            include Deps[
              "operations.user.verify_ownership",
              update_preferences: "operations.user.preferences.update"
            ]

            params do
              required(:user_name).filled(:string)
              optional(:timezone).maybe(:string)
              optional(:locale).maybe(:string)
              optional(:relative_timestamps).maybe(:string)
            end

            def handle(request, response)
              result = verify_ownership.call(
                current_user: current_user(request),
                user_name: request.params[:user_name]
              )
              case result
              in Failure(Symbol => status)
                halt status
              in Success(user)
                case update_preferences.call(
                  user:,
                  timezone: request.params[:timezone],
                  locale: request.params[:locale],
                  relative_timestamps: request.params[:relative_timestamps] == "true"
                )
                in Failure(Symbol => status)
                  halt status
                in Success({locale:, **})
                  json_response(response, {locale:})
                end
              end
            end
          end
        end
      end
    end
  end
end
