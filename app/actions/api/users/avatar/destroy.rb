# frozen_string_literal: true

module PastaAtlas
  module Actions
    module API
      module Users
        module Avatar
          class Destroy < PastaAtlas::Action
            include Deps[
              "operations.user.verify_ownership",
              destroy_avatar: "operations.user.avatar.destroy"
            ]

            def handle(request, response)
              result = verify_ownership.call(
                current_user: current_user(request),
                user_name: request.params[:user_name]
              )
              case result
              in Failure(Symbol => status)
                halt status
              in Success(user)
                case destroy_avatar.call(user:)
                in Failure(Symbol => status)
                  halt status
                in Success
                  response.status = :no_content
                end
              end
            end
          end
        end
      end
    end
  end
end
