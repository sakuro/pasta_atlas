# frozen_string_literal: true

RSpec.describe PastaAtlas::Repos::UserProfileRepo, :db do
  let(:repo) { Hanami.app["repos.user_profile_repo"] }
  let(:user) { Factory[:user] }

  describe "#find_or_create_by_user_id" do
    it "creates the profile" do
      profile = repo.find_or_create_by_user_id(user_id: user.id, display_name: "Guest", avatar_s3_key: "guest/avatar/guest.png")

      expect(profile).to have_attributes(user_id: user.id, display_name: "Guest", avatar_s3_key: "guest/avatar/guest.png")
    end

    it "keeps an existing profile as it is" do
      repo.find_or_create_by_user_id(user_id: user.id, display_name: "Old", avatar_s3_key: "old.png")

      profile = repo.find_or_create_by_user_id(user_id: user.id, display_name: "New", avatar_s3_key: "new.png")

      expect(profile).to have_attributes(display_name: "Old", avatar_s3_key: "old.png")
    end
  end

  describe "#find_by_user_id!" do
    it "raises for a user without a profile" do
      expect { repo.find_by_user_id!(user.id) }.to raise_error(ROM::TupleCountMismatchError)
    end
  end
end
