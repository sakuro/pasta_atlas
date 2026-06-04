# frozen_string_literal: true

module PastaAtlas
  module Actions
    module API
      module Users
        class Destroy < PastaAtlas::Action
          include Deps[
            "operations.user.verify_ownership",
            destroy_user: "operations.user.destroy"
          ]

          def handle(request, response)
            halt :bad_request if request.params[:confirm_user_name] != request.params[:user_name]

            result = verify_ownership.call(
              current_user: current_user(request),
              user_name: request.params[:user_name]
            )
            case result
            in Failure(Symbol => status)
              halt status
            in Success(user)
              case destroy_user.call(user:)
              in Success
                request.session.clear
                json_response(response, {redirect_to: "/"})
              in Failure(Symbol => status)
                halt status
              end
            end
          end
        end
      end
    end
  end
end
