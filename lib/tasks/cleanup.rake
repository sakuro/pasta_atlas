# frozen_string_literal: true

include Dry::Monads[:result]

namespace :cleanup do
  desc "Delete orphaned S3 objects for maps that no longer exist in the database"
  task orphaned_s3_objects: :environment do
    case Hanami.app["operations.cleanup_orphaned_s3_objects"].call
    in Success(stats)
      puts "Deleted #{stats[:deleted_count]} orphaned S3 prefix(es)"
    in Failure(reason)
      warn "Cleanup failed: #{reason}"
      exit 1
    end
  end
end
