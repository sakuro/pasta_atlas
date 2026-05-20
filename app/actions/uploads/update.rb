# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Uploads
      class Update < PastaAtlas::Action
        include Deps["operations.uploads.update_status"]

        def handle(request, response)
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
          in Failure(Symbol => status)
            halt status
          end
        end
      end
    end
  end
end
