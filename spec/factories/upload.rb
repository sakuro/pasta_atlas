# frozen_string_literal: true

require "ulid"

Factory.define(:upload) do |f|
  f.ulid { ULID.generate }
  f.status "pending"
  f.total_image_count 5
  f.association(:generation)

  f.trait(:complete) do |t|
    t.status "complete"
    t.completed_at { Time.now }
  end
end
