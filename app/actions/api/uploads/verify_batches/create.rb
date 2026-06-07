# frozen_string_literal: true

module PastaAtlas
  module Actions
    module API
      module Uploads
        module VerifyBatches
          class Create < PastaAtlas::Action
            include Deps[
              "operations.uploads.verify_batch",
              "repos.generation_repo",
              "repos.map_repo",
              "repos.upload_repo"
            ]

            contract do
              params do
                required(:ulid).filled(:string)
                required(:filenames).array(:string)
              end

              rule(:filenames) do
                key.failure("must not be empty") if values[:filenames].empty?
                key.failure("too many filenames") if values[:filenames].length > 200
              end
            end

            def handle(request, response)
              halt :bad_request unless request.params.valid?
              halt :forbidden if current_user_id(request) == guest_user_id

              upload = upload_repo.find_by_ulid(request.params[:ulid])
              halt :not_found unless upload

              generation = generation_repo.find_by_id(upload.generation_id)
              map = map_repo.find_by_id(generation.map_id)
              halt :forbidden unless map.user_id == current_user_id(request)

              result = verify_batch.call(upload:, filenames: request.params[:filenames])

              case result
              in Success({verified_bytes:})
                json_response(response, {verified_bytes:})
              in Failure(:verification_failed)
                json_response(response, {error: "verification_failed"}, status: 422)
              in Failure(Symbol => status)
                halt status
              end
            end
          end
        end
      end
    end
  end
end
