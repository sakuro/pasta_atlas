# frozen_string_literal: true

require "ulid"

module PastaAtlas
  module Operations
    module Uploads
      class Create < PastaAtlas::Operation
        include Deps[
          "repos.generation_repo",
          "repos.upload_repo",
          "settings",
          find_or_create_map: "operations.maps.find_or_create",
          s3_client: "s3.client"
        ]

        def call(user_id:, metadata:, total_image_count:)
          mapshot_map_id = metadata["map_id"]
          mapshot_unique_id = metadata["unique_id"]
          tick = Integer(metadata["tick"])

          map = step find_or_create_map.call(
            user_id:,
            mapshot_map_id:,
            savename: metadata.fetch("savename", "").to_s,
            name: metadata["name"]
          )

          within_transaction(
            map:,
            mapshot_map_id:,
            mapshot_unique_id:,
            tick:,
            metadata:,
            total_image_count:
          )
        end

        private def within_transaction(map:, mapshot_map_id:, mapshot_unique_id:, tick:, metadata:, total_image_count:)
          result = nil
          generation_repo.db.transaction do
            generation = generation_repo.find_with_upload(
              map_id: map.id, mapshot_unique_id:
            )
            if generation
              result = result_for_existing_generation(generation)
              raise Sequel::Rollback if result.failure?

              next
            end
            result = create_generation_and_upload(
              map:, mapshot_map_id:, mapshot_unique_id:, tick:, metadata:, total_image_count:
            )
            raise Sequel::Rollback if result.failure?
          end
          result
        end

        private def create_generation_and_upload(map:, mapshot_map_id:, mapshot_unique_id:, tick:, metadata:, total_image_count:)
          metadata_s3_key = "#{mapshot_map_id}/#{mapshot_unique_id}/mapshot.json"
          generation = generation_repo.create(
            ulid: ULID.generate,
            map_id: map.id,
            mapshot_unique_id:,
            tick:,
            metadata_s3_key:
          )
          write_result = write_metadata_to_s3(key: metadata_s3_key, body: metadata.to_json)
          return write_result unless write_result.success?

          upload = upload_repo.create(
            ulid: ULID.generate,
            generation_id: generation.id,
            status: "pending",
            total_image_count:
          )
          Success(upload)
        end

        private def result_for_existing_generation(generation)
          upload = generation.upload
          upload&.status == "complete" ? Failure(:conflict) : Success(upload)
        end

        private def write_metadata_to_s3(key:, body:)
          s3_client.put_object(
            bucket: settings.s3_bucket,
            key:,
            body:,
            content_type: "application/json"
          )
          Success(key)
        rescue Aws::S3::Errors::ServiceError
          Failure(:s3_error)
        end
      end
    end
  end
end
