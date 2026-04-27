# frozen_string_literal: true

require "ulid"

Factory.define(:map) do |f|
  f.ulid { ULID.generate }
  f.sequence(:mapshot_map_id) {|n| "map%010d" % n }
  f.savename ""
  f.association(:user)
end
