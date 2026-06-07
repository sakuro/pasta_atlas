# frozen_string_literal: true

require "concurrent"

module PastaAtlas
  module Operations
    module Uploads
      class VerifyBatch < PastaAtlas::Operation
        include Deps[
          "repos.generation_repo",
          "repos.map_repo",
          "repos.upload_repo",
          "repos.upload_verification_key_repo",
          "repos.user_repo",
          "settings",
          s3_client: "s3.client"
        ]

        CONCURRENCY = 20
        private_constant :CONCURRENCY

        def call(upload:, filenames:)
          generation = generation_repo.find_by_id(upload.generation_id)
          map = map_repo.find_by_id(generation.map_id)
          user = user_repo.find_by_id(map.user_id)
          prefix = "#{user.name}/maps/#{map.mapshot_map_id}/#{generation.mapshot_unique_id}/"

          s3_keys = filenames.map {|f| "#{prefix}#{f}" }
          results = head_objects(s3_keys)

          return Failure(:verification_failed) if results.any?(&:nil?)

          upload_verification_key_repo.mark_verified_batch(upload_id: upload.id, results:)
          batch_bytes = results.sum {|r| r[:size_bytes] }
          upload_repo.accumulate_verified_bytes(id: upload.id, bytes: batch_bytes)

          {verified_bytes: batch_bytes}
        end

        private def head_objects(keys)
          keys.each_slice(CONCURRENCY).flat_map do |slice|
            futures = slice.map {|key| Concurrent::Future.execute { head_object(key) } }
            futures.map(&:value)
          end
        end

        private def head_object(key)
          response = s3_client.head_object(bucket: settings.s3_bucket, key:)
          {s3_key: key, size_bytes: response.content_length}
        rescue Aws::S3::Errors::NotFound, Aws::S3::Errors::NoSuchKey
          nil
        end
      end
    end
  end
end
