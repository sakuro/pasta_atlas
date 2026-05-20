# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Uploads
      class Create < PastaAtlas::Action
        include Deps[create_upload: "operations.uploads.create"]

        def handle(request, response)
          result = create_upload.call(
            user_id: current_user_or_guest_id(request),
            metadata: request.params[:metadata].to_h.transform_keys(&:to_s),
            total_image_count: request.params[:total_image_count],
            name: request.params[:name].then {|n| n&.empty? ? nil : n }
          )

          case result
          in Success({upload:, generation:, map:})
            json_response(
              response,
              {
                ulid: upload.ulid,
                map_ulid: map.ulid,
                generation_ulid: generation.ulid
              },
              status: 201
            )
          in Failure(:s3_error)
            halt :bad_gateway
          in Failure(Symbol => status)
            halt status
          end
        end
      end
    end
  end
end
