# frozen_string_literal: true

include Dry::Monads[:result]

namespace :maps do
  desc "Delete a map and its S3 objects. Specify the map ULID via MAP_ULID env var."
  task delete: :environment do
    ulid = ENV.fetch("MAP_ULID", nil)
    abort "MAP_ULID is required" unless ulid

    map_repo = Hanami.app["repos.map_repo"]
    map = map_repo.find_by_ulid(ulid)

    unless map
      warn "Map not found: #{ulid}"
      next
    end

    user = Hanami.app["repos.user_repo"].find_by_id(map.user_id)
    s3_prefix = "#{user.name}/#{map.mapshot_map_id}/"

    map_repo.delete_by_id(map.id)
    puts "Deleted map record: #{ulid}"

    case Hanami.app["operations.maps.delete"].call(s3_prefix:)
    in Success(_)
      puts "Deleted S3 objects under #{s3_prefix}"
    in Failure(reason)
      warn "Failed to delete S3 objects under #{s3_prefix}: #{reason}"
      exit 1
    end
  end
end
