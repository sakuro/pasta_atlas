# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Uploads
      class Create < PastaAtlas::Action
        include Deps[
          "repos.generation_repo",
          "repos.map_repo",
          create_upload: "operations.uploads.create"
        ]

        def handle(request, response)
          user_id = current_user_or_guest_id(request)
          unless user_id
            response.status = 401
            return
          end

          result = create_upload.call(
            user_id:,
            metadata: request.params[:metadata].to_h.transform_keys(&:to_s),
            total_image_count: request.params[:total_image_count]
          )

          case result
          in Success(upload)
            generation = generation_repo.find_by_id(upload.generation_id)
            map = map_repo.find_by_id(generation.map_id)
            json_response(
              response,
              {
                ulid: upload.ulid,
                map_ulid: map.ulid,
                generation_ulid: generation.ulid
              },
              status: 201
            )
          in Failure(:conflict)
            response.status = 409
          in Failure(:s3_error)
            response.status = 502
          end
        end
      end
    end
  end
end
