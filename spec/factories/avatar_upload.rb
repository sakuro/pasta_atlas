# frozen_string_literal: true

require "ulid"

Factory.define(:avatar_upload) do |f|
  f.association(:user)
  f.s3_key { "testuser/avatar/#{ULID.generate}.png" }
  f.content_type "image/png"
  f.expires_at { Time.now + 3600 }
end
