# frozen_string_literal: true

Factory.define(:upload_event) do |f|
  f.event_type "pending"
  f.occurred_at { Time.now }
  f.association(:upload)
end
