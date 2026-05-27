# frozen_string_literal: true

require "ulid"

Factory.define(:upload) do |f|
  f.ulid { ULID.generate }
  f.total_image_count 5
  f.association(:generation)
end
