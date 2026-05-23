# frozen_string_literal: true

require "tzinfo"

module PastaAtlas
  module Actions
    module User
      class Show < PastaAtlas::Action
        include Deps[
          "operations.user.find_by_name",
          list_recent_maps: "operations.maps.list_recent_by_user",
          load_credentials: "operations.user.credentials.load",
          load_preferences: "operations.user.preferences.load",
          load_profile: "operations.user.profile.load"
        ]

        OAUTH_PROVIDERS = %w[discord github steam].freeze
        private_constant :OAUTH_PROVIDERS

        def handle(request, response)
          result = find_by_name.call(user_name: request.params[:user_name])
          case result
          in Failure(Symbol => status)
            halt status
          in Success(user)
            halt :not_found if user.guest?

            is_owner = current_user_id(request) == user.id
            profile_data = load_profile.call(user_id: user.id).value!
            avatar_url = profile_data[:avatar_url]
            user_info = Values::UserInfo[name: user.name, display_name: profile_data[:display_name] || user.name, avatar_url:]
            recent_map_infos = list_recent_maps.call(user_id: user.id, user_info:).value!

            render_params = {
              user_name: user.name,
              display_name: profile_data[:display_name],
              avatar_url:,
              recent_map_infos:,
              is_owner:,
              error: nil,
              timezone: nil,
              timezone_identifiers: [],
              locale: nil,
              supported_locales: [],
              providers: [],
              connected_providers: []
            }

            if is_owner
              preference = load_preferences.call(user_id: user.id, viewer_id: user.id).value!
              connected_providers = load_credentials.call(user_id: user.id, viewer_id: user.id).value!
              render_params.merge!(
                timezone: preference.timezone,
                timezone_identifiers: TZInfo::Timezone.all_identifiers,
                locale: preference.locale,
                supported_locales: PastaAtlas::I18n::SUPPORTED_LOCALES,
                providers: OAUTH_PROVIDERS,
                connected_providers:
              )
            end

            response.render view, **render_params
          end
        end
      end
    end
  end
end
