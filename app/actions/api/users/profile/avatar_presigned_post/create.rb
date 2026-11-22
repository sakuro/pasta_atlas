# frozen_string_literal: true

module PastaAtlas
  module Actions
    module API
      module Users
        module Profile
          module AvatarPresignedPost
            class Create < PastaAtlas::Action
              include Deps[
                "operations.user.verify_ownership",
                create_avatar_presigned_post: "operations.user.avatar_presigned_post.create"
              ]

              params do
                required(:user_name).filled(:string)
                required(:content_type).filled(:string, included_in?: %w[image/jpeg image/png image/webp])
              end

              def handle(request, response)
                halt :bad_request unless request.params.valid?

                result = verify_ownership.call(
                  current_user: current_user(request),
                  user_name: request.params[:user_name]
                )
                case result
                in Failure(Symbol => status)
                  halt status
                in Success(user)
                  result = create_avatar_presigned_post.call(
                    user_id: user.id,
                    content_type: request.params[:content_type]
                  )
                  case result
                  in Failure(Symbol => status)
                    halt status
                  in Success({presigned_post:, s3_key:})
                    json_response(response, {presigned_post:, s3_key:})
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
