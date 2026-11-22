# frozen_string_literal: true

module PastaAtlas
  module Operations
    module Uploads
      class IssuePresignedPosts < PastaAtlas::Operation
        include Deps[
          "repos.generation_repo",
          "repos.map_repo",
          "repos.upload_repo",
          "repos.upload_verification_key_repo",
          "repos.user_repo",
          "settings",
          s3_client: "s3.client"
        ]

        MAX_IMAGE_SIZE_BYTES = 640 * 1024
        private_constant :MAX_IMAGE_SIZE_BYTES

        REQUIRED_CONTENT_TYPE = "image/jpeg"
        private_constant :REQUIRED_CONTENT_TYPE

        def call(upload_ulid:, filenames:, user_id:)
          upload = step find_upload(upload_ulid)
          step validate_pending(upload)

          generation = generation_repo.find_by_id!(upload.generation_id)
          map = map_repo.find_by_id!(generation.map_id)
          step validate_ownership(map, user_id)
          user = user_repo.find_by_id!(map.user_id)

          prefix = "#{user.name}/maps/#{map.mapshot_map_id}/#{generation.mapshot_unique_id}/"

          filenames = filenames.uniq
          s3_keys = filenames.map {|f| "#{prefix}#{f}" }
          step validate_within_total(upload, s3_keys)
          upload_verification_key_repo.create_many(upload_id: upload.id, s3_keys:)

          presigned_posts_for(filenames:, prefix:)
        end

        private def validate_within_total(upload, s3_keys)
          recorded = upload_verification_key_repo.count(upload_id: upload.id)
          # Asking again for a file already issued is a retry and adds nothing, so only the keys
          # new to the upload count.
          new_keys = s3_keys.size - upload_verification_key_repo.count_among(upload_id: upload.id, s3_keys:)
          # Not locked: two concurrent requests can pass together and overshoot by one batch,
          # which the 200 filenames per request bound.
          recorded + new_keys <= upload.total_image_count ? Success() : Failure(:unprocessable_entity)
        end

        private def validate_ownership(map, user_id) = map.user_id == user_id ? Success() : Failure(:forbidden)

        private def find_upload(ulid)
          upload = upload_repo.find_by_ulid(ulid)
          upload ? Success(upload) : Failure(:not_found)
        end

        private def validate_pending(upload)
          upload.pending? ? Success(upload) : Failure(:unprocessable_entity)
        end

        private def presigned_posts_for(filenames:, prefix:)
          bucket = Aws::S3::Bucket.new(name: settings.s3_bucket, client: s3_client)
          expiry = Time.now + settings.presigned_url_expiry

          filenames.each_with_object({}) do |filename, posts|
            key = "#{prefix}#{filename}"
            post = bucket.presigned_post(
              key:,
              content_type: REQUIRED_CONTENT_TYPE,
              content_length_range: 1..MAX_IMAGE_SIZE_BYTES,
              expires: expiry
            )
            posts[filename] = {url: post.url, fields: post.fields}
          end
        end
      end
    end
  end
end
