# frozen_string_literal: true

module PastaAtlas
  module Operations
    class CleanupOrphanedS3Objects < PastaAtlas::Operation
      SKIP_PREFIXES = %w[avatars/].freeze
      private_constant :SKIP_PREFIXES

      include Deps["repos.map_repo", "repos.user_repo", "settings", s3_client: "s3.client"]

      def call
        deleted_count = step cleanup_orphaned_prefixes
        {deleted_count:}
      end

      private def cleanup_orphaned_prefixes
        deleted_count = 0
        list_prefixes("").each do |user_prefix|
          next if SKIP_PREFIXES.include?(user_prefix)

          user_name = user_prefix.chomp("/")
          user = user_repo.find_by_name(user_name)
          next unless user

          list_prefixes(user_prefix).each do |map_prefix|
            mapshot_map_id = map_prefix.delete_prefix(user_prefix).chomp("/")
            unless map_repo.find_by_user_and_mapshot_id(user_id: user.id, mapshot_map_id:)
              delete_objects(map_prefix)
              deleted_count += 1
            end
          end
        end
        Success(deleted_count)
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
