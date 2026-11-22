# frozen_string_literal: true

module PastaAtlas
  module Operations
    # Deletes the S3 prefixes of maps that are missing from the database. A map record is created
    # before any object under its prefix is written, so a prefix without a record is not in use.
    # With dry_run, the prefixes are only listed.
    class CleanupOrphanedMaps < PastaAtlas::Operation
      include Deps["repos.map_repo", "repos.user_repo", "settings", s3_client: "s3.client"]

      def call(dry_run: false)
        prefixes = step find_orphaned_prefixes
        step delete_prefixes(prefixes) unless dry_run
        {prefixes:, deleted_count: dry_run ? 0 : prefixes.size}
      end

      private def find_orphaned_prefixes
        prefixes = []
        list_prefixes("").each do |user_prefix|
          user_name = user_prefix.chomp("/")
          user = user_repo.find_by_name(user_name)
          next unless user

          maps_prefix = "#{user_prefix}maps/"
          list_prefixes(maps_prefix).each do |map_prefix|
            mapshot_map_id = map_prefix.delete_prefix(maps_prefix).chomp("/")
            prefixes << map_prefix unless map_repo.find_by_user_and_mapshot_id(user_id: user.id, mapshot_map_id:)
          end
        end
        Success(prefixes)
      rescue Aws::S3::Errors::ServiceError
        Failure(:s3_error)
      end

      private def delete_prefixes(prefixes)
        prefixes.each {|prefix| delete_objects(prefix) }
        Success()
      rescue Aws::S3::Errors::ServiceError
        Failure(:s3_error)
      end

      private def list_prefixes(prefix)
        prefixes = []
        s3_client.list_objects_v2(bucket: settings.s3_bucket, prefix:, delimiter: "/").each_page do |page|
          prefixes.concat(page.common_prefixes.map(&:prefix))
        end
        prefixes
      end

      private def delete_objects(prefix)
        s3_client.list_objects_v2(bucket: settings.s3_bucket, prefix:).each_page do |page|
          keys = page.contents.map {|obj| {key: obj.key} }
          next if keys.empty?

          s3_client.delete_objects(
            bucket: settings.s3_bucket,
            delete: {objects: keys, quiet: true}
          )
        end
      end
    end
  end
end
