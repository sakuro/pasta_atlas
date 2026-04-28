# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Uploads
      module PresignedUrls
        class Create < PastaAtlas::Action
          include Deps[issue_presigned_urls: "operations.uploads.issue_presigned_urls"]

          def handle(request, response)
            user_id = current_user_id(request)
            unless user_id
              response.status = 401
              return
            end

            result = issue_presigned_urls.call(
              upload_ulid: request.params[:ulid],
              filenames: request.params[:filenames]
            )

            case result
            in Success(urls)
              json_response(response, {presigned_urls: urls})
            in Failure(:not_found)
              response.status = 404
            in Failure(:unprocessable)
              response.status = 422
            end
          end
        end
      end
    end
  end
end
