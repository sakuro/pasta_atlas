# frozen_string_literal: true

RSpec.describe PastaAtlas::Repos::UserPreferenceRepo, :db do
  let(:repo) { Hanami.app["repos.user_preference_repo"] }
  let(:user) { Factory[:user] }

  describe "#find_or_create_by_user_id" do
    it "creates the preferences once and keeps the existing ones" do
      first = repo.find_or_create_by_user_id(user_id: user.id)
      repo.update_preferences(user.id, timezone: "Asia/Tokyo", locale: "ja", relative_timestamps: true)

      second = repo.find_or_create_by_user_id(user_id: user.id)

      expect([second.id, second.timezone]).to eq([first.id, "Asia/Tokyo"])
    end
  end
end
