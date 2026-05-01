# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Auth
      module Registrations
        class Create < PastaAtlas::Action
          include Deps["repos.credential_repo", "repos.user_profile_repo"]

          USERNAME_PATTERN = /\A[a-zA-Z0-9][a-zA-Z0-9_-]*[a-zA-Z0-9]\z|\A[a-zA-Z0-9]\z/
          private_constant :USERNAME_PATTERN
          RESERVED_NAMES = %w[guest api admin].freeze
          private_constant :RESERVED_NAMES

          params do
            required(:name).filled(:string)
          end

          def handle(request, response)
            pending = request.session[:pending_auth]
            halt 403 unless pending

            name = request.params[:name].to_s.downcase

            error = validate_name(name)
            if error
              response.render(view, suggested_name: name, error:)
              return
            end

            user = user_repo.find_by_name(name)
            if user
              response.render view, suggested_name: name, error: "That username is already taken."
              return
            end

            user_repo.db.transaction do
              user = user_repo.create(name:)
              user_profile_repo.user_profiles.command(:create).call(user_id: user.id)
              credential_repo.credentials.command(:create).call(
                user_id: user.id,
                provider: pending["provider"],
                uid: pending["uid"],
                data: {}
              )
            end

            request.session.delete(:pending_auth)
            request.session[:user_id] = user.id
            response.redirect_to "/"
          end

          private def validate_name(name)
            return "Username must not be empty." if name.empty?
            return "Username must be 39 characters or fewer." if name.length > 39
            return "Username may only contain letters, numbers, hyphens, and underscores, and must start and end with a letter or number." unless name.match?(USERNAME_PATTERN)
            return "That username is reserved." if RESERVED_NAMES.include?(name)

            nil
          end
        end
      end
    end
  end
end
