# frozen_string_literal: true

module PastaAtlas
  module Operations
    module Generations
      class CalculateStorage < PastaAtlas::Operation
        include Deps[
          "repos.generation_repo",
          "settings",
          s3_client: "s3.client"
        ]

        def call(generation_id:)
          generation = generation_repo.find_by_id(generation_id)
          prefix = generation.metadata_s3_key.delete_suffix("mapshot.json")
          total_bytes = step sum_s3_objects(prefix)
          generation_repo.update_storage_bytes(id: generation_id, storage_bytes: total_bytes)
          total_bytes
        end

        private def sum_s3_objects(prefix)
          total = 0
          s3_client.list_objects_v2(bucket: settings.s3_bucket, prefix:).each_page do |page|
            total += page.contents.sum(&:size)
          end
          Success(total)
        rescue Aws::S3::Errors::ServiceError
          Failure(:s3_error)
        end
      end
    end
  end
end
