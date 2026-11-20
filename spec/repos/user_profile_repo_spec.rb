# frozen_string_literal: true

RSpec.describe PastaAtlas::Repos::UserProfileRepo, :db do
  let(:repo) { Hanami.app["repos.user_profile_repo"] }
  let(:user) { Factory[:user] }

  describe "#upsert" do
    it "creates the profile" do
      profile = repo.upsert(user_id: user.id, display_name: "Guest", avatar_s3_key: "guest/avatar/guest.png")

      expect(profile).to have_attributes(user_id: user.id, display_name: "Guest", avatar_s3_key: "guest/avatar/guest.png")
    end

    it "replaces the display name and the avatar of an existing profile" do
      repo.upsert(user_id: user.id, display_name: "Old", avatar_s3_key: "old.png")

      profile = repo.upsert(user_id: user.id, display_name: "New", avatar_s3_key: "new.png")

      expect(profile).to have_attributes(display_name: "New", avatar_s3_key: "new.png")
    end
  end

  describe "#find_by_user_id!" do
    it "raises for a user without a profile" do
      expect { repo.find_by_user_id!(user.id) }.to raise_error(ROM::TupleCountMismatchError)
    end
  end
end
