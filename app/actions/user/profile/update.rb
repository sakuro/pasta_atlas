# frozen_string_literal: true

require "tzinfo"

module PastaAtlas
  module Actions
    module User
      module Profile
        class Update < PastaAtlas::Action
          include Deps[
            list_recent_maps: "operations.maps.list_recent_by_user",
            load_credentials: "operations.user.credentials.load",
            load_preferences: "operations.user.preferences.load",
            load_profile: "operations.user.profile.load",
            show_view: "views.user.show",
            update_profile: "operations.user.profile.update"
          ]

          OAUTH_PROVIDERS = %w[discord github steam].freeze
          private_constant :OAUTH_PROVIDERS

          params do
            required(:user_name).filled(:string)
            required(:display_name).filled(:string)
            optional(:avatar_s3_key).maybe(:string)
          end

          def handle(request, response)
            result = update_profile.call(
              user_id: current_user_id(request),
              user_name: request.params[:user_name],
              display_name: request.params[:display_name].to_s,
              avatar_s3_key: request.params[:avatar_s3_key].to_s
            )
            case result
            in Failure(:invalid, error)
              user_id = current_user_id(request)
              user_name = request.params[:user_name]
              profile_data = load_profile.call(user_id:).value!
              avatar_url = profile_data[:avatar_url]
              preference = load_preferences.call(user_id:, viewer_id: user_id).value!
              connected_providers = load_credentials.call(user_id:, viewer_id: user_id).value!
              user_info = Values::UserInfo[name: user_name, display_name: profile_data[:display_name] || user_name, avatar_url:]
              recent_map_infos = list_recent_maps.call(user_id:, user_info:).value!
              response.render(
                show_view,
                user_name:,
                display_name: request.params[:display_name].to_s,
                avatar_url:,
                recent_map_infos:,
                is_owner: true,
                error:,
                timezone: preference.timezone,
                timezone_identifiers: TZInfo::Timezone.all_identifiers,
                locale: preference.locale,
                supported_locales: PastaAtlas::I18n::SUPPORTED_LOCALES,
                providers: OAUTH_PROVIDERS,
                connected_providers:
              )
            in Failure(Symbol => status)
              halt status
            in Success(user)
              response.redirect_to "/@#{user.name}#edit-profile"
            end
          end
        end
      end
    end
  end
end
