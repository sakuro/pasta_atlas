# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Uploads
      module PresignedUrls
        class Create < PastaAtlas::Action
          include Deps["operations.uploads.issue_presigned_urls"]

          def handle(request, response)
            result = issue_presigned_urls.call(
              upload_ulid: request.params[:ulid],
              filenames: request.params[:filenames]
            )

            case result
            in Success(urls)
              json_response(response, {presigned_urls: urls})
            in Failure(:not_found)
              halt 404
            in Failure(:unprocessable)
              halt 422
            end
          end
        end
      end
    end
  end
end
