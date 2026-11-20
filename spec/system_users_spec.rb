# frozen_string_literal: true

RSpec.describe PastaAtlas::SystemUsers, :db do
  let(:seeds) { Pathname(Hanami.app.root).join("config/db/seeds.rb") }
  let(:user_repo) { Hanami.app["repos.user_repo"] }
  let(:user_profile_repo) { Hanami.app["repos.user_profile_repo"] }
  let(:user_preference_repo) { Hanami.app["repos.user_preference_repo"] }

  def seed = load(seeds)

  it "creates every seeded user with a profile and preferences" do
    seed

    PastaAtlas::SystemUsers::SEEDED.each do |system_user|
      user = user_repo.find_by_name(system_user.name)

      expect(user_profile_repo.find_by_user_id!(user.id)).to have_attributes(display_name: system_user.display_name, avatar_s3_key: system_user.avatar_s3_key)
      expect(user_preference_repo.find_by_user_id!(user.id)).not_to be_nil
    end
  end

  it "can run again without changing anything" do
    seed
    ids = PastaAtlas::SystemUsers::SEEDED.map {|system_user| user_repo.find_by_name(system_user.name).id }

    seed

    expect(PastaAtlas::SystemUsers::SEEDED.map {|system_user| user_repo.find_by_name(system_user.name).id }).to eq(ids)
  end

  it "reserves the seeded names and the names without an account" do
    expect(PastaAtlas::SystemUsers::RESERVED_NAMES).to contain_exactly("guest", "compilatron", "api", "admin")
  end
end
