# frozen_string_literal: true

require "tzinfo"

module PastaAtlas
  module Actions
    module Profile
      class Update < PastaAtlas::Action
        include Deps[
          "repos.user_profile_repo",
          "repos.user_preference_repo",
          edit_view: "views.profile.edit"
        ]

        DISPLAY_NAME_MAX_GRAPHEME_CLUSTERS = 64
        private_constant :DISPLAY_NAME_MAX_GRAPHEME_CLUSTERS

        # Reject: Unicode whitespace (\p{Space}), C0/C1 control characters (\p{Cc}),
        # and format characters (\p{Cf}) EXCEPT:
        #   U+200D  ZWJ — joins multi-codepoint emoji sequences (e.g. 👨‍💻, 🏳️‍🌈)
        #   U+FE00–U+FE0F  Variation Selectors 1–16 — emoji/text presentation (e.g. ❤️)
        #   U+E0100–U+E01EF  Variation Selectors Supplement — CJK ideograph variants
        DISALLOWED_CHARS = /[\p{Space}\p{Cc}]|[\p{Cf}&&[^\u{200D}\u{FE00}-\u{FE0F}\u{E0100}-\u{E01EF}]]/
        private_constant :DISALLOWED_CHARS

        params do
          required(:user_name).filled(:string)
          required(:display_name).filled(:string)
          optional(:timezone).maybe(:string)
          optional(:avatar_s3_key).maybe(:string)
        end

        def handle(request, response)
          user_id = current_user_id(request)
          halt 403 unless user_id

          user_name = request.params[:user_name]
          halt 403 unless user_repo.find_by_id(user_id).name == user_name

          display_name = request.params[:display_name].to_s
          timezone = valid_timezone(request.params[:timezone])

          error = validate_display_name(display_name)
          if error
            timezone_identifiers = TZInfo::Timezone.all_identifiers
            response.render(edit_view, display_name:, timezone:, timezone_identifiers:, error:)
            return
          end

          user_profile_repo.update_profile(user_id, display_name: display_name.empty? ? nil : display_name)
          user_preference_repo.update_preferences(user_id, timezone:)

          avatar_s3_key = request.params[:avatar_s3_key].to_s
          if !avatar_s3_key.empty? && avatar_s3_key.start_with?("avatars/#{user_id}/")
            user_profile_repo.update_avatar(user_id, avatar_s3_key:)
          end

          response.redirect_to "/@#{user_name}/profile"
        end

        private def valid_timezone(name)
          TZInfo::Timezone.get(name.to_s).name
        rescue TZInfo::InvalidTimezoneIdentifier, TZInfo::InvalidDataFile
          "UTC"
        end

        private def validate_display_name(name)
          return nil if name.empty?
          return "Display name must be 64 characters or fewer." if name.scan(/\X/).length > DISPLAY_NAME_MAX_GRAPHEME_CLUSTERS
          return "Display name contains disallowed characters." if name.match?(DISALLOWED_CHARS)

          nil
        end
      end
    end
  end
end
