# frozen_string_literal: true

require "ulid"

module PastaAtlas
  module Operations
    module User
      module AvatarPresignedUrl
        class Create < PastaAtlas::Operation
          ALLOWED_CONTENT_TYPES = {
            "image/jpeg" => "jpg",
            "image/png" => "png",
            "image/webp" => "webp"
          }.freeze
          private_constant :ALLOWED_CONTENT_TYPES

          include Deps["settings", s3_client: "s3.client"]

          def call(user_id:, content_type:)
            user_id = step require_authentication(user_id)
            ext = step resolve_extension(content_type)
            key = "avatars/#{user_id}/#{ULID.generate}.#{ext}"
            presigned_url = step generate_presigned_url(key:, content_type:)
            Success({presigned_url:, s3_key: key})
          end

          private def require_authentication(user_id)
            user_id ? Success(user_id) : Failure(:forbidden)
          end

          private def resolve_extension(content_type)
            ext = ALLOWED_CONTENT_TYPES[content_type]
            ext ? Success(ext) : Failure(:unprocessable_entity)
          end

          private def generate_presigned_url(key:, content_type:)
            presigner = Aws::S3::Presigner.new(client: s3_client)
            url = presigner.presigned_url(
              :put_object,
              bucket: settings.s3_bucket,
              key:,
              expires_in: settings.presigned_url_expiry,
              content_type:
            )
            Success(url)
          end
        end
      end
    end
  end
end
