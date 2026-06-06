# frozen_string_literal: true

require "ulid"

module PastaAtlas
  module Operations
    module Uploads
      class Create < PastaAtlas::Operation
        include Deps[
          "repos.generation_repo",
          "repos.upload_event_repo",
          "repos.upload_repo",
          "repos.user_repo",
          "settings",
          find_or_create_map: "operations.maps.find_or_create",
          s3_client: "s3.client"
        ]

        MAP_NAME_MAX_GRAPHEME_CLUSTERS = 30
        private_constant :MAP_NAME_MAX_GRAPHEME_CLUSTERS

        def call(user_id:, metadata:, total_image_count:, name: nil)
          mapshot_map_id = metadata[:map_id]
          mapshot_unique_id = metadata[:unique_id]
          tick = Integer(metadata[:tick])
          user = user_repo.find_by_id(user_id)

          step validate_name(name) if name

          map = step find_or_create_map.call(
            user_id:,
            mapshot_map_id:,
            savename: metadata.fetch(:savename, "").to_s,
            name:,
            update_name_on_conflict: user.can_rename_map?
          )

          step within_transaction(
            map:,
            user:,
            mapshot_map_id:,
            mapshot_unique_id:,
            tick:,
            metadata:,
            total_image_count:
          )
        end

        private def validate_name(name)
          return Failure([:invalid, "error-map-name-too-long"]) if grapheme_clusters_exceed?(name, MAP_NAME_MAX_GRAPHEME_CLUSTERS)
          return Failure([:invalid, "error-map-name-invalid-chars"]) if name.match?(DISALLOWED_CHARS)

          Success()
        end

        private def within_transaction(map:, user:, mapshot_map_id:, mapshot_unique_id:, tick:, metadata:, total_image_count:)
          result = nil
          generation_repo.transaction do
            if generation_repo.all_expired_for_map?(map_id: map.id)
              result = Failure(:gone)
              next
            end

            generation = generation_repo.find_with_upload(
              map_id: map.id, mapshot_unique_id:
            )
            if generation
              result = result_for_existing_generation(generation, map)
              raise Sequel::Rollback if result.failure?

              next
            end
            result = create_generation_and_upload(
              map:, user:, mapshot_map_id:, mapshot_unique_id:, tick:, metadata:, total_image_count:
            )
            raise Sequel::Rollback if result.failure?
          end
          result
        end

        private def create_generation_and_upload(map:, user:, mapshot_map_id:, mapshot_unique_id:, tick:, metadata:, total_image_count:)
          metadata_s3_key = "#{user.name}/maps/#{mapshot_map_id}/#{mapshot_unique_id}/mapshot.json"
          generation = generation_repo.create(
            ulid: ULID.generate,
            map_id: map.id,
            mapshot_unique_id:,
            tick:,
            metadata_s3_key:,
            expires_at: nil
          )
          write_result = write_metadata_to_s3(key: metadata_s3_key, body: metadata.to_json)
          return write_result unless write_result.success?

          upload = upload_repo.create(
            ulid: ULID.generate,
            generation_id: generation.id,
            total_image_count:
          )
          upload_event_repo.create(upload_id: upload.id, event_type: "pending")
          upload = upload_repo.find_by_ulid(upload.ulid)
          Success({upload:, generation:, map:})
        end

        private def result_for_existing_generation(generation, map)
          upload = generation.upload
          upload.complete? ? Failure(:conflict) : Success({upload:, generation:, map:})
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
