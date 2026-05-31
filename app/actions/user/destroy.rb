# frozen_string_literal: true

module PastaAtlas
  module Actions
    module User
      class Destroy < PastaAtlas::Action
        include Deps[destroy_user: "operations.user.destroy"]

        def handle(request, response)
          halt :bad_request if request.params[:confirm_user_name] != request.params[:user_name]

          result = destroy_user.call(
            user_id: current_user_id(request),
            user_name: request.params[:user_name]
          )
          case result
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
