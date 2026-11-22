# frozen_string_literal: true

include Dry::Monads[:result]

namespace :cleanup do
  desc "Delete the S3 objects of maps that no longer exist in the database (DRY_RUN=1 only lists them)"
  task orphaned_maps: :environment do
    dry_run = ENV.key?("DRY_RUN")
    case Hanami.app["operations.cleanup_orphaned_maps"].call(dry_run:)
    in Success(stats)
      if dry_run
        stats[:prefixes].each {|prefix| puts prefix }
        puts "Found #{stats[:prefixes].size} orphaned map prefix(es); nothing was deleted"
      else
        puts "Deleted #{stats[:deleted_count]} orphaned map prefix(es)"
      end
    in Failure(reason)
      warn "Cleanup failed: #{reason}"
      exit 1
    end
  end

  desc "Delete avatar objects that no profile refers to"
  task orphaned_avatars: :environment do
    case Hanami.app["operations.cleanup_orphaned_avatars"].call
    in Success(stats)
      puts "Deleted #{stats[:deleted_count]} orphaned avatar object(s)"
    in Failure(reason)
      warn "Cleanup failed: #{reason}"
      exit 1
    end
  end

  desc "Delete generations of uploads that were started and then abandoned"
  task stale_uploads: :environment do
    stats = Hanami.app["operations.uploads.cleanup_stale"].call.value!
    puts "Deleted #{stats[:deleted]} of #{stats[:found]} stale upload(s)"
    if stats[:failed].positive?
      warn "#{stats[:failed]} stale upload(s) could not be queued for cleanup"
      exit 1
    end
  end
end
