# frozen_string_literal: true

module PastaAtlas
  module Operations
    module Uploads
      class IssuePresignedUrls < PastaAtlas::Operation
        include Deps[
          "repos.generation_repo",
          "repos.map_repo",
          "repos.upload_repo",
          "repos.user_repo",
          "settings",
          s3_client: "s3.client"
        ]

        # file_prefix = "s" .. surface.index .. "zoom_":
        # https://github.com/Palats/mapshot/blob/ddad172f187d08e56df720efe2fe0bddfb65e347/mod/control.lua#L295
        # path = data_prefix .. "tile_" .. tile_x .. "_" .. tile_y .. ".jpg":
        # https://github.com/Palats/mapshot/blob/ddad172f187d08e56df720efe2fe0bddfb65e347/mod/control.lua#L338
        TILE_FILENAME_PATTERN = %r{\As\d+zoom_\d+/tile_-?\d+_-?\d+\.jpg\z}
        private_constant :TILE_FILENAME_PATTERN

        def call(upload_ulid:, filenames:, user_id:)
          upload = step find_upload(upload_ulid)
          step validate_pending(upload)
          step validate_filenames(filenames)

          generation = generation_repo.find_by_id(upload.generation_id)
          map = map_repo.find_by_id(generation.map_id)
          step validate_ownership(map, user_id)
          user = user_repo.find_by_id(map.user_id)

          prefix = "#{user.name}/#{map.mapshot_map_id}/#{generation.mapshot_unique_id}/"
          existing_keys = step list_existing_keys(prefix)

          presigned_urls_for(filenames:, prefix:, existing_keys:)
        end

        private def validate_ownership(map, user_id) = map.user_id == user_id ? Success() : Failure(:forbidden)

        private def validate_filenames(filenames)
          return Failure(:unprocessable_entity) unless filenames.is_a?(Array)
          return Failure(:unprocessable_entity) unless filenames.all? {|f| f.is_a?(String) && TILE_FILENAME_PATTERN.match?(f) }

          Success()
        end

        private def find_upload(ulid)
          upload = upload_repo.find_by_ulid(ulid)
          upload ? Success(upload) : Failure(:not_found)
        end

        private def validate_pending(upload)
          upload.pending? ? Success(upload) : Failure(:unprocessable_entity)
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
