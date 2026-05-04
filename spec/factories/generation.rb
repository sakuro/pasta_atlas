# frozen_string_literal: true

require "ulid"

Factory.define(:generation) do |f|
  f.ulid { ULID.generate }
  f.sequence(:mapshot_unique_id) {|n| "gen%010d" % n }
  f.tick 1000
  f.metadata_s3_key {|mapshot_unique_id| "#{mapshot_unique_id}/mapshot.json" }
  f.expires_at nil
  f.association(:map)

  f.trait(:expired) do |t|
    t.expires_at { Time.now - 86400 }
  end
end
