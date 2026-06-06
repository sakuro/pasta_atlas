# frozen_string_literal: true

# This seeds file should create the database records required to run the app.
#
# The code should be idempotent so that it can be executed at any time.
#
# To load the seeds, run `hanami db seed`. Seeds are also loaded as part of `hanami db prepare`.

users = Hanami.app["relations.users"]
user_profiles = Hanami.app["relations.user_profiles"]
user_preferences = Hanami.app["relations.user_preferences"]

db = users.dataset.db

db.transaction do
  users.dataset.insert_conflict(target: :name).insert(name: "guest")

  guest_id = users.dataset.where(name: "guest").get(:id)
  user_profiles.dataset.insert_conflict(target: :user_id, update: {display_name: "Guest", avatar_s3_key: "guest/avatar/guest.png"}).insert(user_id: guest_id, display_name: "Guest", avatar_s3_key: "guest/avatar/guest.png")
  user_preferences.dataset.insert_conflict(target: :user_id).insert(user_id: guest_id)

  users.dataset.insert_conflict(target: :name).insert(name: "compilatron")

  compilatron_id = users.dataset.where(name: "compilatron").get(:id)
  user_profiles.dataset.insert_conflict(target: :user_id, update: {display_name: "Compilatron", avatar_s3_key: "compilatron/avatar/compilatron.png"}).insert(user_id: compilatron_id, display_name: "Compilatron", avatar_s3_key: "compilatron/avatar/compilatron.png")
  user_preferences.dataset.insert_conflict(target: :user_id).insert(user_id: compilatron_id)
end
