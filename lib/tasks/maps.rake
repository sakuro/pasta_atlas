# frozen_string_literal: true

namespace :maps do
  desc "Delete a map and its S3 objects by ULID"
  task :delete_by_ulid, [:ulid] => :environment do |_, args|
    ulid = args[:ulid]
    abort "Usage: rake maps:delete_by_ulid[ULID]" unless ulid

    result = Hanami.app["operations.maps.delete"].call(ulid:)
    if result.success?
      puts "Deleted map #{ulid}"
    else
      warn "Failed to delete map #{ulid}: #{result.failure}"
      exit 1
    end
  end
end
