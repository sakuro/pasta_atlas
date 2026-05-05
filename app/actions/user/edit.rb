# frozen_string_literal: true

require "tzinfo"

module PastaAtlas
  module Actions
    module User
      class Edit < PastaAtlas::Action
        include Deps["repos.user_profile_repo", "repos.user_preference_repo", "settings"]

        def handle(request, response)
          user_id = current_user_id(request)
          halt 403 unless user_id
          halt 403 unless user_repo.find_by_id(user_id).name == request.params[:user_name]

          profile = user_profile_repo.find_by_user_id(user_id)
          preference = user_preference_repo.find_by_user_id(user_id)
          timezone_identifiers = TZInfo::Timezone.all_identifiers
          avatar_url = profile.avatar_s3_key ? "#{settings.cloudfront_base_url}/#{profile.avatar_s3_key}" : nil
          response.render view,
            display_name: profile.display_name.to_s,
            timezone: preference.timezone,
            timezone_identifiers:,
            locale: preference.locale,
            avatar_url:
        end
      end
    end
  end
end
