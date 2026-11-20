# frozen_string_literal: true

module PastaAtlas
  module Actions
    module API
      module Auth
        class Current < PastaAtlas::Action
          include Deps[
            find_user: "operations.user.find_by_id",
            load_preferences: "operations.user.preferences.load",
            load_profile: "operations.user.profile.load"
          ]

          def handle(request, response)
            user_id = current_user_id(request)
            return json_response(response, {user: nil, preferences: guest_preferences}) if user_id == guest_user_id

            # A session can outlive its user, for example when the account is deleted from another
            # device. Drop the stale id so that signing in starts from a clean session.
            user = find_user.call(user_id:).value_or { return forget_user(request, response) }
            profile_data = load_profile.call(user_id:).value!
            preference = load_preferences.call(user_id:).value!
            json_response(response, {
              user: {
                name: user.name,
                display_name: profile_data[:display_name] || user.name,
                avatar_url: profile_data[:avatar_url]
              },
              preferences: {
                locale: preference.locale,
                timezone: preference.timezone,
                relative_timestamps: preference.relative_timestamps
              }
            })
          rescue ROM::TupleCountMismatchError
            forget_user(request, response)
          end

          private def forget_user(request, response)
            # Session#delete passes the key on as it is, unlike Session#[], and the session is keyed by strings.
            request.session.delete("user_id")
            json_response(response, {user: nil, preferences: guest_preferences})
          end

          private def guest_preferences = {locale: nil, timezone: nil, relative_timestamps: false}
        end
      end
    end
  end
end
