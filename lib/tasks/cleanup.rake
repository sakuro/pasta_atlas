# frozen_string_literal: true

include Dry::Monads[:result]

namespace :cleanup do
  desc "Delete expired guest generations and orphaned maps"
  task guest_maps: :environment do
    case Hanami.app["operations.cleanup_guest_maps"].call
    in Success(stats)
      puts "Deleted #{stats[:deleted_generations]} guest generation(s) and #{stats[:deleted_maps]} orphaned map(s)"
    in Failure(reason)
      warn "Cleanup failed: #{reason}"
      exit 1
    end
  end

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
