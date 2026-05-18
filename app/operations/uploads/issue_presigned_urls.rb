# frozen_string_literal: true

module PastaAtlas
  module Operations
    module Uploads
      class IssuePresignedUrls < PastaAtlas::Operation
        include Deps[
          "repos.upload_repo",
          "repos.generation_repo",
          "repos.map_repo",
          "repos.user_repo",
          "settings",
          s3_client: "s3.client"
        ]

        def call(upload_ulid:, filenames:)
          upload = step find_upload(upload_ulid)
          step validate_pending(upload)

          generation = generation_repo.find_by_id(upload.generation_id)
          map = map_repo.find_by_id(generation.map_id)
          user = user_repo.find_by_id(map.user_id)

          prefix = "#{user.name}/#{map.mapshot_map_id}/#{generation.mapshot_unique_id}/"
          existing_keys = step list_existing_keys(prefix)

          presigned_urls_for(filenames:, prefix:, existing_keys:)
        end

        private def find_upload(ulid)
          upload = upload_repo.find_by_ulid(ulid)
          upload ? Success(upload) : Failure(:not_found)
        end

        private def validate_pending(upload)
          upload.pending? ? Success(upload) : Failure(:unprocessable)
        end

        private def list_existing_keys(prefix)
          keys = s3_client.list_objects_v2(
            bucket: settings.s3_bucket,
            prefix:
          ).contents.map(&:key)
          Success(keys)
        rescue Aws::S3::Errors::ServiceError
          Failure(:s3_error)
        end

        private def presigned_urls_for(filenames:, prefix:, existing_keys:)
          existing = existing_keys.to_set
          presigner = Aws::S3::Presigner.new(client: s3_client)

          filenames.each_with_object({}) do |filename, urls|
            key = "#{prefix}#{filename}"
            next if existing.include?(key)

            urls[filename] = presigner.presigned_url(
              :put_object,
              bucket: settings.s3_bucket,
              key:,
              expires_in: settings.presigned_url_expiry
            )
          end
        end
      end
    end
  end
end
