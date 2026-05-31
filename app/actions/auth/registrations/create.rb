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
            optional(:terms).maybe(:string)
          end

          def handle(request, response)
            pending = request.session[:pending_auth]
            halt :forbidden unless pending

            unless request.params[:terms] == "1"
              return json_response(response, {error: "error-terms-required"}, status: 422)
            end

            name = request.params[:name].to_s.downcase
            result = create_registration.call(
              name:,
              timezone: request.params[:timezone].to_s,
              provider: pending["provider"],
              uid: pending["uid"],
              avatar_url: pending["avatar_url"]
            )
            case result
            in Dry::Monads::Result::Failure(:invalid, error_key)
              json_response(response, {error: error_key}, status: 422)
            in Dry::Monads::Result::Failure(Symbol => status)
              halt status
            in Success(user)
              request.session.delete(:pending_auth)
              request.session[:user_id] = user.id
              json_response(response, {redirect_to: "/"})
            end
          end
        end
      end
    end
  end
end
