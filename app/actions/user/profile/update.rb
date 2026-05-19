# frozen_string_literal: true

require "tzinfo"

module PastaAtlas
  module Actions
    module User
      module Profile
        class Update < PastaAtlas::Action
          include Deps[
            "repos.credential_repo",
            "settings",
            "repos.user_preference_repo",
            "repos.user_profile_repo",
            "operations.user.verify_ownership",
            edit_view: "views.user.edit"
          ]

          OAUTH_PROVIDERS = %w[discord github].freeze
          private_constant :OAUTH_PROVIDERS

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
            optional(:avatar_s3_key).maybe(:string)
          end

          def handle(request, response)
            result = verify_ownership.call(
              user_id: current_user_id(request),
              user_name: request.params[:user_name]
            )
            case result
            in Failure(status)
              halt status
            in Success(user)
              display_name = request.params[:display_name].to_s

              error = validate_display_name(display_name)
              if error
                preference = user_preference_repo.find_by_user_id(user.id)
                profile = user_profile_repo.find_by_user_id(user.id)
                timezone_identifiers = TZInfo::Timezone.all_identifiers
                avatar_url = profile.avatar_s3_key ? "#{settings.cloudfront_base_url}/#{profile.avatar_s3_key}" : nil
                connected_providers = credential_repo.find_by_user_id(user.id).map(&:provider)
                response.render(
                  edit_view,
                  user_name: user.name,
                  display_name:,
                  timezone: preference.timezone,
                  timezone_identifiers:,
                  locale: preference.locale,
                  avatar_url:,
                  supported_locales: PastaAtlas::I18n::SUPPORTED_LOCALES,
                  providers: OAUTH_PROVIDERS,
                  connected_providers:,
                  flash_error: nil,
                  error:
                )
                return
              end

              user_profile_repo.update_profile(user.id, display_name: display_name.empty? ? nil : display_name)

              avatar_s3_key = request.params[:avatar_s3_key].to_s
              if !avatar_s3_key.empty? && avatar_s3_key.start_with?("avatars/#{user.id}/")
                user_profile_repo.update_avatar(user.id, avatar_s3_key:)
              end

              response.redirect_to "/@#{user.name}"
            end
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
end
