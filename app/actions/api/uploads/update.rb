# frozen_string_literal: true

module PastaAtlas
  module Actions
    module API
      module Uploads
        class Update < PastaAtlas::Action
          include Deps["operations.uploads.update_status"]

          params do
            required(:ulid).filled(:string)
            required(:status).filled(:string, included_in?: %w[complete failed])
          end

          def handle(request, response)
            halt :bad_request unless request.params.valid?

            result = update_status.call(
              upload_ulid: request.params[:ulid],
              status: request.params[:status],
              user_id: current_user_or_guest_id(request)
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
end
