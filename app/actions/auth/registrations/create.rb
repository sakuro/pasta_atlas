# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Auth
      module Registrations
        class Create < PastaAtlas::Action
          include Deps[create_registration: "operations.registrations.create"]

          params do
            required(:name).filled(:string)
            optional(:timezone).maybe(:string)
          end

          def handle(request, response)
            pending = request.session[:pending_auth]
            halt 403 unless pending

            name = request.params[:name].to_s.downcase
            result = create_registration.call(
              name:,
              timezone: request.params[:timezone].to_s,
              provider: pending["provider"],
              uid: pending["uid"],
              avatar_url: pending["avatar_url"]
            )
            case result
            in Failure(:invalid, error_key)
              response.render(view, suggested_name: name, error: i18n(request).format(error_key))
            in Failure(status)
              halt status
            in Success(user)
              request.session.delete(:pending_auth)
              request.session[:user_id] = user.id
              response.redirect_to "/"
            end
          end
        end
      end
    end
  end
end
