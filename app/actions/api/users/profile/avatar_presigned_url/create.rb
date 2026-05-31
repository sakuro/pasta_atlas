# frozen_string_literal: true

module PastaAtlas
  module Actions
    module API
      module Users
        module Profile
          module AvatarPresignedUrl
            class Create < PastaAtlas::Action
              include Deps[
                "operations.user.verify_ownership",
                create_avatar_presigned_url: "operations.user.avatar_presigned_url.create"
              ]

              params do
                required(:content_type).filled(:string, included_in?: %w[image/jpeg image/png image/webp])
              end

              def handle(request, response)
                halt :bad_request unless request.params.valid?

                result = verify_ownership.call(
                  user_id: current_user_id(request),
                  user_name: request.params[:user_name]
                )
                case result
                in Failure(Symbol => status)
                  halt status
                in Success
                  result = create_avatar_presigned_url.call(
                    user_id: current_user_id(request),
                    content_type: request.params[:content_type]
                  )
                  case result
                  in Failure(Symbol => status)
                    halt status
                  in Success({presigned_url:, s3_key:})
                    json_response(response, {presigned_url:, s3_key:})
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
