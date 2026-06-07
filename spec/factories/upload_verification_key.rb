# frozen_string_literal: true

require "ulid"

Factory.define(:upload_verification_key) do |f|
  f.s3_key { "testuser/maps/#{ULID.generate[0, 8].downcase}/#{ULID.generate[0, 8].downcase}/s0zoom_4/tile_0_0.jpg" }
  f.verified_at { Time.now }
  f.size_bytes 1024
  f.association(:upload)
end
