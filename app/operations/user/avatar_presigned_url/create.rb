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

          include Deps["repos.user_repo", "settings", s3_client: "s3.client"]

          def call(user_id:, content_type:)
            user_id = step require_authentication(user_id)
            ext = step resolve_extension(content_type)
            user = user_repo.find_by_id(user_id)
            key = "#{user.name}/avatar/#{ULID.generate}.#{ext}"
            presigned_url = generate_presigned_url(key:, content_type:)
            {presigned_url:, s3_key: key}
          end

          private def require_authentication(user_id)
            user_id ? Success(user_id) : Failure(:forbidden)
          end

          private def resolve_extension(content_type)
            ext = ALLOWED_CONTENT_TYPES[content_type]
            ext ? Success(ext) : Failure(:unprocessable_entity)
          end

          private def generate_presigned_url(key:, content_type:)
            Aws::S3::Presigner.new(client: s3_client).presigned_url(
              :put_object,
              bucket: settings.s3_bucket,
              key:,
              expires_in: settings.presigned_url_expiry,
              content_type:
            )
          end
        end
      end
    end
  end
end
