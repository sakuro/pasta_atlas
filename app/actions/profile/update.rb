# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Profile
      class Update < PastaAtlas::Action
        include Deps[
          "repos.user_profile_repo",
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
        end

        def handle(request, response)
          user_id = current_user_id(request)
          halt 403 unless user_id

          user_name = request.params[:user_name]
          halt 403 unless user_repo.find_by_id(user_id).name == user_name

          display_name = request.params[:display_name].to_s

          error = validate_display_name(display_name)
          if error
            response.render(edit_view, display_name:, error:)
            return
          end

          user_profile_repo.update_display_name(user_id, display_name.empty? ? nil : display_name)
          response.redirect_to "/@#{user_name}/profile"
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
