# frozen_string_literal: true

require "tzinfo"

module PastaAtlas
  module Actions
    module User
      class Edit < PastaAtlas::Action
        include Deps[
          "operations.user.verify_ownership",
          load_credentials: "operations.user.credentials.load",
          load_preferences: "operations.user.preferences.load",
          load_profile: "operations.user.profile.load"
        ]

        OAUTH_PROVIDERS = %w[discord github steam].freeze
        private_constant :OAUTH_PROVIDERS

        def handle(request, response)
          result = verify_ownership.call(
            user_id: current_user_id(request),
            user_name: request.params[:user_name]
          )
          case result
          in Failure(Symbol => status)
            halt status
          in Success(user)
            profile_data = load_profile.call(user_id: user.id).value!
            preference = load_preferences.call(user_id: user.id, viewer_id: user.id).value!
            connected_providers = load_credentials.call(user_id: user.id, viewer_id: user.id).value!
            timezone_identifiers = TZInfo::Timezone.all_identifiers
            flash_error = request.flash[:error]
            response.render view,
              user_name: user.name,
              display_name: profile_data[:display_name].to_s,
              timezone: preference.timezone,
              timezone_identifiers:,
              locale: preference.locale,
              avatar_url: profile_data[:avatar_url],
              supported_locales: PastaAtlas::I18n::SUPPORTED_LOCALES,
              providers: OAUTH_PROVIDERS,
              connected_providers:,
              flash_error:
          end
        end
      end
    end
  end
end
