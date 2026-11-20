# frozen_string_literal: true

# This seeds file should create the database records required to run the app.
#
# The code should be idempotent so that it can be executed at any time.
#
# To load the seeds, run `hanami db seed`. Seeds are also loaded as part of `hanami db prepare`.

user_repo = Hanami.app["repos.user_repo"]
user_profile_repo = Hanami.app["repos.user_profile_repo"]
user_preference_repo = Hanami.app["repos.user_preference_repo"]

user_repo.transaction do
  PastaAtlas::SystemUsers::SEEDED.each do |system_user|
    user = user_repo.find_or_create_by_name(name: system_user.name)
    user_profile_repo.find_or_create_by_user_id(user_id: user.id, display_name: system_user.display_name, avatar_s3_key: system_user.avatar_s3_key)
    user_preference_repo.find_or_create_by_user_id(user_id: user.id)
  end
end
