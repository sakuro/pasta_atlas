# frozen_string_literal: true

module PastaAtlas
  module Actions
    module User
      module AvatarPresignedUrl
        class Create < PastaAtlas::Action
          include Deps[create_avatar_presigned_url: "operations.user.avatar_presigned_url.create"]

          def handle(request, response)
            result = create_avatar_presigned_url.call(
              user_id: current_user_id(request),
              content_type: request.params[:content_type].to_s
            )
            case result
            in Failure(status)
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
