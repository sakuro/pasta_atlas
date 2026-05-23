# frozen_string_literal: true

module PastaAtlas
  module Operations
    module Maps
      class Delete < PastaAtlas::Operation
        include Deps["settings", s3_client: "s3.client"]

        def call(s3_prefix:)
          step delete_s3_objects(s3_prefix)
          s3_prefix
        end

        private def delete_s3_objects(s3_prefix)
          s3_client.list_objects_v2(bucket: settings.s3_bucket, prefix: s3_prefix).each_page do |page|
            keys = page.contents.map {|obj| {key: obj.key} }
            next if keys.empty?

            s3_client.delete_objects(
              bucket: settings.s3_bucket,
              delete: {objects: keys, quiet: true}
            )
          end
          Success(nil)
        rescue Aws::S3::Errors::ServiceError
          Failure(:s3_error)
        end
      end
    end
  end
end
