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
          "repos.upload_verification_key_repo",
          "settings",
          s3_client: "s3.client",
          sqs_client: "sqs.client"
        ]

        def call(upload_ulid:, status:, user_id:)
          upload = step find_upload(upload_ulid)
          step validate_ownership(upload, user_id)
          step validate_completeness(upload) if status == "complete"
          step append_event(upload, status)
          finalize_verification(upload) if status == "complete"
          step find_upload(upload_ulid)
        end

        private def validate_ownership(upload, user_id)
          generation = generation_repo.find_by_id(upload.generation_id)
          map = map_repo.find_by_id(generation.map_id)
          map.user_id == user_id ? Success() : Failure(:forbidden)
        end

        private def validate_completeness(upload)
          verified_count = upload_verification_key_repo.count_verified(upload_id: upload.id)
          verified_count == upload.total_image_count ? Success() : Failure(:incomplete)
        end

        private def find_upload(ulid)
          upload = upload_repo.find_by_ulid(ulid)
          upload ? Success(upload) : Failure(:not_found)
        end

        private def append_event(upload, status)
          upload_event_repo.create(upload_id: upload.id, event_type: status)
          Success()
        end

        private def finalize_verification(upload)
          generation = generation_repo.find_by_id(upload.generation_id)
          metadata_bytes = head_object_size(generation.metadata_s3_key) || 0
          storage_bytes = upload.verified_bytes + metadata_bytes
          generation_repo.update_storage_bytes(id: upload.generation_id, storage_bytes:)
          upload_repo.update_verification(id: upload.id, verification_status: "passed", verified_at: Time.now)
        rescue
          # storage_bytes remains NULL until backfill
        end

        private def head_object_size(key)
          s3_client.head_object(bucket: settings.s3_bucket, key:).content_length
        rescue Aws::S3::Errors::NotFound, Aws::S3::Errors::NoSuchKey
          nil
        end
      end
    end
  end
end
