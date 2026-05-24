# frozen_string_literal: true

require "ulid"

module PastaAtlas
  module Operations
    module Uploads
      class Create < PastaAtlas::Operation
        # One day shorter than the S3 lifecycle (8 days) so DB records are cleaned up before S3 objects disappear.
        GUEST_TTL_DAYS = 7
        private_constant :GUEST_TTL_DAYS

        include Deps[
          "repos.generation_repo",
          "repos.upload_repo",
          "repos.user_repo",
          "settings",
          find_or_create_map: "operations.maps.find_or_create",
          s3_client: "s3.client"
        ]

        # gen_map_id / gen_unique_id produce 8 hex chars sliced from SHA-256:
        # https://github.com/Palats/mapshot/blob/ddad172f187d08e56df720efe2fe0bddfb65e347/mod/control.lua#L206-L222
        MAPSHOT_ID_PATTERN = /\A[0-9a-f]{8}\z/
        private_constant :MAPSHOT_ID_PATTERN

        # game.tick is an unsigned 32-bit counter:
        # https://lua-api.factorio.com/latest/classes/LuaGameScript.html#tick
        TICK_MAX = 4_294_967_295
        private_constant :TICK_MAX

        def call(user_id:, metadata:, total_image_count:, name: nil)
          mapshot_map_id = metadata["map_id"]
          mapshot_unique_id = metadata["unique_id"]
          tick = metadata["tick"]
          step validate_metadata(mapshot_map_id:, mapshot_unique_id:, tick:)
          tick = Integer(tick)
          user = user_repo.find_by_id(user_id)

          map = step find_or_create_map.call(
            user_id:,
            mapshot_map_id:,
            savename: metadata.fetch("savename", "").to_s,
            name:
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

        private def validate_metadata(mapshot_map_id:, mapshot_unique_id:, tick:)
          return Failure(:unprocessable_entity) unless mapshot_map_id.is_a?(String) && MAPSHOT_ID_PATTERN.match?(mapshot_map_id)
          return Failure(:unprocessable_entity) unless mapshot_unique_id.is_a?(String) && MAPSHOT_ID_PATTERN.match?(mapshot_unique_id)

          tick_int = Integer(tick, exception: false)
          return Failure(:unprocessable_entity) unless tick_int && tick_int.between?(0, TICK_MAX)

          Success()
        end

        private def within_transaction(map:, user:, mapshot_map_id:, mapshot_unique_id:, tick:, metadata:, total_image_count:)
          result = nil
          generation_repo.transaction do
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
          metadata_s3_key = "#{user.name}/#{mapshot_map_id}/#{mapshot_unique_id}/mapshot.json"
          generation = generation_repo.create(
            ulid: ULID.generate,
            map_id: map.id,
            mapshot_unique_id:,
            tick:,
            metadata_s3_key:,
            expires_at: user.guest? ? Time.now + (GUEST_TTL_DAYS * 86400) : nil
          )
          write_result = write_metadata_to_s3(key: metadata_s3_key, body: metadata.to_json)
          return write_result unless write_result.success?

          upload = upload_repo.create(
            ulid: ULID.generate,
            generation_id: generation.id,
            status: "pending",
            total_image_count:
          )
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
