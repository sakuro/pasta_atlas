# frozen_string_literal: true

require "tzinfo"

module PastaAtlas
  module Actions
    module Auth
      module Registrations
        class Create < PastaAtlas::Action
          include Deps[
            "repos.credential_repo",
            "repos.user_profile_repo",
            "repos.user_preference_repo",
            "operations.registrations.import_avatar"
          ]

          USERNAME_PATTERN = /\A[a-zA-Z0-9][a-zA-Z0-9_-]*[a-zA-Z0-9]\z|\A[a-zA-Z0-9]\z/
          private_constant :USERNAME_PATTERN
          RESERVED_NAMES = %w[guest api admin].freeze
          private_constant :RESERVED_NAMES

          params do
            required(:name).filled(:string)
            optional(:timezone).maybe(:string)
          end

          def handle(request, response)
            pending = request.session[:pending_auth]
            halt 403 unless pending

            name = request.params[:name].to_s.downcase

            error_key = validate_name(name)
            if error_key
              response.render(view, suggested_name: name, error: i18n(request).format(error_key))
              return
            end

            user = user_repo.find_by_name(name)
            if user
              response.render view, suggested_name: name, error: i18n(request).format("error-username-taken")
              return
            end

            timezone = valid_timezone(request.params[:timezone])

            user_repo.transaction do
              user = user_repo.create(name:)
              user_profile_repo.user_profiles.command(:create).call(user_id: user.id)
              user_preference_repo.user_preferences.command(:create).call(user_id: user.id, timezone:)
              credential_repo.credentials.command(:create).call(
                user_id: user.id,
                provider: pending["provider"],
                uid: pending["uid"],
                data: {}
              )
            end

            avatar_result = import_avatar.call(user_id: user.id, avatar_url: pending["avatar_url"])
            user_profile_repo.update_avatar(user.id, avatar_s3_key: avatar_result.value!) if avatar_result.success?

            request.session.delete(:pending_auth)
            request.session[:user_id] = user.id
            response.redirect_to "/"
          end

          private def valid_timezone(name)
            TZInfo::Timezone.get(name.to_s).name
          rescue TZInfo::InvalidTimezoneIdentifier, TZInfo::InvalidDataFile
            "UTC"
          end

          private def validate_name(name)
            return "error-username-empty" if name.empty?
            return "error-username-too-long" if name.length > 39
            return "error-username-invalid-chars" unless name.match?(USERNAME_PATTERN)
            return "error-username-reserved" if RESERVED_NAMES.include?(name)

            nil
          end
        end
      end
    end
  end
end
