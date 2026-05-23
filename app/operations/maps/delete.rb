# frozen_string_literal: true

module PastaAtlas
  module Operations
    module Maps
      class Delete < PastaAtlas::Operation
        include Deps["repos.map_repo", "repos.user_repo", "settings", s3_client: "s3.client"]

        def call(ulid:)
          map = step find_map(ulid)
          user = step find_user(map.user_id)
          map_repo.delete_by_id(map.id)
          step delete_s3_objects(user, map)
          map
        end

        private def find_map(ulid)
          map = map_repo.find_by_ulid(ulid)
          map ? Success(map) : Failure(:not_found)
        end

        private def find_user(user_id)
          Success(user_repo.find_by_id(user_id))
        end

        private def delete_s3_objects(user, map)
          prefix = "#{user.name}/#{map.mapshot_map_id}/"
          s3_client.list_objects_v2(bucket: settings.s3_bucket, prefix:).each_page do |page|
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
