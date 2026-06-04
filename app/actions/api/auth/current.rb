# frozen_string_literal: true

module PastaAtlas
  module Actions
    module API
      module Auth
        class Current < PastaAtlas::Action
          include Deps[
            "repos.user_preference_repo",
            "repos.user_profile_repo",
            "repos.user_repo",
            "settings"
          ]

          def handle(request, response)
            user_id = current_user_id(request)
            return json_response(response, {user: nil, preferences: guest_preferences}) unless user_id

            user = user_repo.find_by_id(user_id)
            profile = user_profile_repo.find_by_user_id(user_id)
            preference = user_preference_repo.find_by_user_id(user_id)
            avatar_url = profile.avatar_s3_key ? "#{settings.cloudfront_base_url}/#{profile.avatar_s3_key}" : nil

            json_response(response, {
              user: {
                name: user.name,
                display_name: profile.display_name || user.name,
                avatar_url:
              },
              preferences: {
                locale: preference.locale,
                timezone: preference.timezone,
                relative_timestamps: preference.relative_timestamps
              }
            })
          rescue ROM::TupleCountMismatchError
            json_response(response, {user: nil, preferences: guest_preferences})
          end

          private def guest_preferences = {locale: nil, timezone: "UTC", relative_timestamps: false}
        end
      end
    end
  end
end
