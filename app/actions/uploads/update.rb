# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Uploads
      class Update < PastaAtlas::Action
        include Deps[update_status: "operations.uploads.update_status"]

        def handle(request, response)
          user_id = current_user_id(request)
          unless user_id
            response.status = 401
            return
          end

          result = update_status.call(
            upload_ulid: request.params[:ulid],
            status: request.params[:status]
          )

          case result
          in Success(upload)
            json_response(response, {
              ulid: upload.ulid,
              status: upload.status,
              completed_at: upload.completed_at&.iso8601
            })
          in Failure(:not_found)
            response.status = 404
          end
        end
      end
    end
  end
end
