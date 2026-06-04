# frozen_string_literal: true

module PastaAtlas
  module Actions
    module API
      module Users
        module Avatar
          class Update < PastaAtlas::Action
            include Deps[
              "operations.user.verify_ownership",
              update_avatar: "operations.user.avatar.update"
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
                case update_avatar.call(user:, s3_key: request.params[:s3_key].to_s)
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
