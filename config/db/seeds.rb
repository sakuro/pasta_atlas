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
  user_profiles.dataset.insert_conflict(target: :user_id).insert(user_id: guest_id, display_name: "Guest")
  user_profiles.dataset.where(user_id: guest_id).update(display_name: "Guest")
  user_preferences.dataset.insert_conflict(target: :user_id).insert(user_id: guest_id)

  users.dataset.each do |user|
    user_profiles.dataset.insert_conflict(target: :user_id).insert(user_id: user[:id])
    user_preferences.dataset.insert_conflict(target: :user_id).insert(user_id: user[:id])
  end
end
