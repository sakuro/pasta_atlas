# frozen_string_literal: true

module PastaAtlas
  module Operations
    module User
      module Profile
        class Update < PastaAtlas::Operation
          include Deps[
            "operations.user.verify_ownership",
            "repos.user_profile_repo"
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

          def call(user_id:, user_name:, display_name:, avatar_s3_key:)
            user = step verify_ownership.call(user_id:, user_name:)
            step validate_display_name(display_name)
            user_profile_repo.update_profile(user.id, display_name: display_name.empty? ? nil : display_name)
            if !avatar_s3_key.empty? && avatar_s3_key.start_with?("#{user.name}/avatar/")
              user_profile_repo.update_avatar(user.id, avatar_s3_key:)
            end
            user
          end

          private def validate_display_name(name)
            return Success() if name.empty?
            return Failure([:invalid, "Display name must be 64 characters or fewer."]) if name.scan(/\X/).length > DISPLAY_NAME_MAX_GRAPHEME_CLUSTERS
            return Failure([:invalid, "Display name contains disallowed characters."]) if name.match?(DISALLOWED_CHARS)

            Success()
          end
        end
      end
    end
  end
end
