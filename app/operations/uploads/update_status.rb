# frozen_string_literal: true

module PastaAtlas
  module Operations
    module Uploads
      class UpdateStatus < PastaAtlas::Operation
        include Deps[
          "repos.generation_repo",
          "repos.map_repo",
          "repos.upload_event_repo",
          "repos.upload_repo",
          "settings",
          sqs_client: "sqs.client"
        ]

        def call(upload_ulid:, status:, user_id:)
          upload = step find_upload(upload_ulid)
          step validate_ownership(upload, user_id)
          step append_event(upload, status)
          enqueue_storage_calculation(upload) if status == "complete"
          step find_upload(upload_ulid)
        end

        private def validate_ownership(upload, user_id)
          generation = generation_repo.find_by_id(upload.generation_id)
          map = map_repo.find_by_id(generation.map_id)
          map.user_id == user_id ? Success() : Failure(:forbidden)
        end

        private def find_upload(ulid)
          upload = upload_repo.find_by_ulid(ulid)
          upload ? Success(upload) : Failure(:not_found)
        end

        private def append_event(upload, status)
          upload_event_repo.create(upload_id: upload.id, event_type: status)
          Success()
        end

        private def enqueue_storage_calculation(upload)
          sqs_client.send_message(
            queue_url: settings.sqs_storage_calculation_queue_url,
            message_body: upload.generation_id.to_s
          )
        rescue Aws::SQS::Errors::ServiceError
          # Storage will remain NULL until backfill
        end
      end
    end
  end
end
