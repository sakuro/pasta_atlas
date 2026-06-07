# frozen_string_literal: true

module PastaAtlas
  module Operations
    module Uploads
      class IssuePresignedUrls < PastaAtlas::Operation
        include Deps[
          "repos.generation_repo",
          "repos.map_repo",
          "repos.upload_repo",
          "repos.upload_verification_key_repo",
          "repos.user_repo",
          "settings",
          s3_client: "s3.client"
        ]

        def call(upload_ulid:, filenames:, user_id:)
          upload = step find_upload(upload_ulid)
          step validate_pending(upload)

          generation = generation_repo.find_by_id(upload.generation_id)
          map = map_repo.find_by_id(generation.map_id)
          step validate_ownership(map, user_id)
          user = user_repo.find_by_id(map.user_id)

          prefix = "#{user.name}/maps/#{map.mapshot_map_id}/#{generation.mapshot_unique_id}/"

          s3_keys = filenames.map {|f| "#{prefix}#{f}" }
          upload_verification_key_repo.create_many(upload_id: upload.id, s3_keys:)

          presigned_urls_for(filenames:, prefix:)
        end

        private def validate_ownership(map, user_id) = map.user_id == user_id ? Success() : Failure(:forbidden)

        private def find_upload(ulid)
          upload = upload_repo.find_by_ulid(ulid)
          upload ? Success(upload) : Failure(:not_found)
        end

        private def validate_pending(upload)
          upload.pending? ? Success(upload) : Failure(:unprocessable_entity)
        end

        private def presigned_urls_for(filenames:, prefix:)
          presigner = Aws::S3::Presigner.new(client: s3_client)

          filenames.each_with_object({}) do |filename, urls|
            key = "#{prefix}#{filename}"
            urls[filename] = presigner.presigned_url(
              :put_object,
              bucket: settings.s3_bucket,
              key:,
              expires_in: settings.presigned_url_expiry,
              content_type: "image/jpeg"
            )
          end
        end
      end
    end
  end
end
