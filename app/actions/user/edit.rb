# frozen_string_literal: true

require "tzinfo"

module PastaAtlas
  module Actions
    module User
      class Edit < PastaAtlas::Action
        include Deps["repos.user_profile_repo", "repos.user_preference_repo", "repos.credential_repo", "settings"]

        OAUTH_PROVIDERS = %w[discord github].freeze
        private_constant :OAUTH_PROVIDERS

        def handle(request, response)
          user_id = current_user_id(request)
          halt 403 unless user_id
          halt 403 unless user_repo.find_by_id(user_id).name == request.params[:user_name]

          profile = user_profile_repo.find_by_user_id(user_id)
          preference = user_preference_repo.find_by_user_id(user_id)
          timezone_identifiers = TZInfo::Timezone.all_identifiers
          avatar_url = profile.avatar_s3_key ? "#{settings.cloudfront_base_url}/#{profile.avatar_s3_key}" : nil
          credentials = credential_repo.find_by_user_id(user_id)
          connected_providers = credentials.map(&:provider)
          flash_error = request.flash[:error]
          response.render view,
            display_name: profile.display_name.to_s,
            timezone: preference.timezone,
            timezone_identifiers:,
            locale: preference.locale,
            avatar_url:,
            supported_locales: PastaAtlas::I18n::SUPPORTED_LOCALES,
            providers: OAUTH_PROVIDERS,
            connected_providers:,
            flash_error:
        end
      end
    end
  end
end
