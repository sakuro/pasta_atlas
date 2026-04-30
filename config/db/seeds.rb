# frozen_string_literal: true

# This seeds file should create the database records required to run the app.
#
# The code should be idempotent so that it can be executed at any time.
#
# To load the seeds, run `hanami db seed`. Seeds are also loaded as part of `hanami db prepare`.

require "ulid"

users = Hanami.app["relations.users"]
user_profiles = Hanami.app["relations.user_profiles"]
maps = Hanami.app["relations.maps"]
generations = Hanami.app["relations.generations"]
uploads = Hanami.app["relations.uploads"]

db = users.dataset.db

db.transaction do
  guest_profile = user_profiles.dataset.where(name: "guest").first
  if guest_profile
    guest_user_id = guest_profile[:user_id]
  else
    guest_user_id = users.dataset.insert({})
    user_profiles.dataset.insert(user_id: guest_user_id, name: "guest")
  end

  maps.dataset.insert_conflict(target: %i[user_id mapshot_map_id]).insert(
    ulid: ULID.generate,
    user_id: guest_user_id,
    mapshot_map_id: "ae8ec3ab",
    savename: ""
  )
  map_id = maps.dataset.where(user_id: guest_user_id, mapshot_map_id: "ae8ec3ab").first[:id]

  generations.dataset.insert_conflict(target: %i[map_id mapshot_unique_id]).insert(
    ulid: ULID.generate,
    map_id:,
    mapshot_unique_id: "550f41a9",
    tick: 29_386_437,
    metadata_s3_key: "guest/ae8ec3ab/550f41a9/mapshot.json"
  )
  generation_id = generations.dataset.where(map_id:, mapshot_unique_id: "550f41a9").first[:id]

  uploads.dataset.insert_conflict(target: :generation_id).insert(
    ulid: ULID.generate,
    generation_id:,
    status: "complete",
    total_image_count: 3311,
    completed_at: Time.now
  )
end
