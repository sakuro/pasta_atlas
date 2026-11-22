# frozen_string_literal: true

require "ulid"

module PastaAtlas
  module Operations
    module User
      module AvatarPresignedPost
        class Create < PastaAtlas::Operation
          ALLOWED_CONTENT_TYPES = {
            "image/jpeg" => "jpg",
            "image/png" => "png",
            "image/webp" => "webp"
          }.freeze
          private_constant :ALLOWED_CONTENT_TYPES

          # Keep in sync with MAX_BYTES in frontend/pages/user/AvatarUpload.tsx.
          MAX_AVATAR_SIZE_BYTES = 5 * 1024 * 1024
          private_constant :MAX_AVATAR_SIZE_BYTES

          include Deps["repos.user_repo", "settings", s3_client: "s3.client"]

          def call(user_id:, content_type:)
            user_id = step require_authentication(user_id)
            user = user_repo.find_by_id!(user_id)
            ext = ALLOWED_CONTENT_TYPES[content_type]
            key = "#{user.name}/avatar/#{ULID.generate}.#{ext}"
            {presigned_post: presigned_post_for(key:, content_type:), s3_key: key}
          end

          private def require_authentication(user_id)
            user_id ? Success(user_id) : Failure(:forbidden)
          end

          private def presigned_post_for(key:, content_type:)
            bucket = Aws::S3::Bucket.new(name: settings.s3_bucket, client: s3_client)
            post = bucket.presigned_post(
              key:,
              content_type:,
              content_length_range: 1..MAX_AVATAR_SIZE_BYTES,
              expires: Time.now + settings.presigned_url_expiry
            )
            {url: post.url, fields: post.fields}
          end
        end
      end
    end
  end
end
