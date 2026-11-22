# frozen_string_literal: true

module PastaAtlas
  module Operations
    # Deletes avatar objects that no profile refers to: replaced or removed avatars whose cleanup
    # was not queued or failed, and uploads that were never applied. Users missing from the
    # database are skipped, as CleanupOrphanedS3Objects does.
    class CleanupOrphanedAvatars < PastaAtlas::Operation
      include Deps["repos.user_profile_repo", "repos.user_repo", "settings", s3_client: "s3.client"]

      # An avatar is uploaded before the profile points at it, so recent objects are not orphans yet.
      GRACE_PERIOD_SECONDS = 24 * 60 * 60
      private_constant :GRACE_PERIOD_SECONDS

      # S3 accepts at most 1000 keys per DeleteObjects request.
      DELETE_BATCH_SIZE = 1000
      private_constant :DELETE_BATCH_SIZE

      def call(now: Time.now)
        deleted_count = step cleanup_orphaned_avatars(now - GRACE_PERIOD_SECONDS)
        {deleted_count:}
      end

      private def cleanup_orphaned_avatars(cutoff)
        deleted_count = 0
        list_user_prefixes.each do |user_prefix|
          user = user_repo.find_by_name(user_prefix.chomp("/"))
          next unless user

          current_key = user_profile_repo.find_by_user_id!(user.id).avatar_s3_key
          deleted_count += delete_unreferenced(user_prefix, current_key, cutoff)
        end
        Success(deleted_count)
      rescue Aws::S3::Errors::ServiceError
        Failure(:s3_error)
      end

      private def list_user_prefixes
        prefixes = []
        s3_client.list_objects_v2(bucket: settings.s3_bucket, prefix: "", delimiter: "/").each_page do |page|
          prefixes.concat(page.common_prefixes.map(&:prefix))
        end
        prefixes
      end

      private def delete_unreferenced(user_prefix, current_key, cutoff)
        keys = []
        s3_client.list_objects_v2(bucket: settings.s3_bucket, prefix: "#{user_prefix}avatar/").each_page do |page|
          page.contents.each {|object| keys << object.key if object.key != current_key && object.last_modified < cutoff }
        end
        keys.each_slice(DELETE_BATCH_SIZE) do |batch|
          s3_client.delete_objects(
            bucket: settings.s3_bucket,
            delete: {objects: batch.map {|key| {key:} }, quiet: true}
          )
        end
        keys.size
      end
    end
  end
end
