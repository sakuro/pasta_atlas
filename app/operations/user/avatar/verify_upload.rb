# frozen_string_literal: true

module PastaAtlas
  module Operations
    module User
      module Avatar
        # Accepts an avatar key only if it was issued to the user, has not expired or been applied,
        # and the stored object is an image of the issued type within the size limit. The key is
        # consumed, so it can be applied once.
        class VerifyUpload < PastaAtlas::Operation
          include Deps["repos.avatar_upload_repo", "settings", s3_client: "s3.client"]

          def call(user:, s3_key:, now: Time.now)
            upload = step find_issued(user, s3_key, now)
            step verify_object(upload)
            step consume(upload, now)
            s3_key
          end

          private def find_issued(user, s3_key, now)
            upload = avatar_upload_repo.find_pending(user_id: user.id, s3_key:, now:)
            upload ? Success(upload) : Failure(:unprocessable_entity)
          end

          private def verify_object(upload)
            head = s3_client.head_object(bucket: settings.s3_bucket, key: upload.s3_key)
            return Failure(:unprocessable_entity) unless acceptable?(head, upload)

            header = s3_client.get_object(
              bucket: settings.s3_bucket,
              key: upload.s3_key,
              range: "bytes=0-#{AvatarPolicy::SIGNATURE_LENGTH - 1}"
            ).body.read
            AvatarPolicy.signature?(upload.content_type, header) ? Success() : Failure(:unprocessable_entity)
          rescue Aws::S3::Errors::NotFound, Aws::S3::Errors::NoSuchKey
            Failure(:unprocessable_entity)
          rescue Aws::S3::Errors::ServiceError
            Failure(:bad_gateway)
          end

          private def acceptable?(head, upload)
            head.content_length.between?(1, AvatarPolicy::MAX_SIZE_BYTES) && head.content_type == upload.content_type
          end

          private def consume(upload, now)
            avatar_upload_repo.consume(id: upload.id, now:).positive? ? Success() : Failure(:unprocessable_entity)
          end
        end
      end
    end
  end
end
