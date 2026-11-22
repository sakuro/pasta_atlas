# frozen_string_literal: true

require "ulid"

module PastaAtlas
  module Operations
    module User
      module AvatarPresignedPost
        class Create < PastaAtlas::Operation
          include Deps["repos.avatar_upload_repo", "repos.user_repo", "settings", s3_client: "s3.client"]

          def call(user_id:, content_type:, now: Time.now)
            user_id = step require_authentication(user_id)
            user = user_repo.find_by_id!(user_id)
            step check_pending_limit(user.id, now)
            key = "#{user.name}/avatar/#{ULID.generate}.#{AvatarPolicy::CONTENT_TYPES[content_type]}"
            expires_at = now + settings.presigned_url_expiry
            avatar_upload_repo.create(user_id: user.id, s3_key: key, content_type:, expires_at:)
            {presigned_post: presigned_post_for(key:, content_type:, expires_at:), s3_key: key}
          end

          private def require_authentication(user_id)
            user_id ? Success(user_id) : Failure(:forbidden)
          end

          private def check_pending_limit(user_id, now)
            pending = avatar_upload_repo.count_pending(user_id:, now:)
            pending < AvatarPolicy::MAX_PENDING_UPLOADS ? Success() : Failure(:too_many_requests)
          end

          private def presigned_post_for(key:, content_type:, expires_at:)
            bucket = Aws::S3::Bucket.new(name: settings.s3_bucket, client: s3_client)
            post = bucket.presigned_post(
              key:,
              content_type:,
              content_length_range: 1..AvatarPolicy::MAX_SIZE_BYTES,
              expires: expires_at
            )
            {url: post.url, fields: post.fields}
          end
        end
      end
    end
  end
end
