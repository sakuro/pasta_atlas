# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::User::Show do
  let(:user_repo) { instance_double(PastaAtlas::Repos::UserRepo) }
  let(:user_profile_repo) { instance_double(PastaAtlas::Repos::UserProfileRepo) }
  let(:user_preference_repo) { instance_double(PastaAtlas::Repos::UserPreferenceRepo) }
  let(:map_repo) { instance_double(PastaAtlas::Repos::MapRepo) }
  let(:generation_repo) { instance_double(PastaAtlas::Repos::GenerationRepo) }
  let(:settings) { double("Settings", cloudfront_base_url: "http://cdn.example.com") }
  let(:action) { PastaAtlas::Actions::User::Show.new(user_repo:, user_profile_repo:, user_preference_repo:, map_repo:, generation_repo:, settings:) }

  let(:user) { double("User", id: 1, name: "sakuro") }
  let(:profile) { double("UserProfile", display_name: "Sakuro", avatar_s3_key: nil) }
  let(:map) { double("Map", id: 1, ulid: "01MAP1", display_name: "My Map") }
  let(:generation) { double("Generation", metadata_s3_key: "sakuro/map1/gen1/mapshot.json") }

  before do
    allow(user_repo).to receive(:find_by_name).with("sakuro").and_return(user)
    allow(user_profile_repo).to receive(:find_by_user_id).with(1).and_return(profile)
    allow(map_repo).to receive(:list_with_complete_generation_by_user).with(user_id: 1, limit: 3).and_return([map])
    allow(generation_repo).to receive(:find_latest_complete_by_map_ids).with([1]).and_return({1 => generation})
    allow(generation_repo).to receive(:find_max_created_at_by_map_ids).with([1]).and_return({})
  end

  context "when the user exists" do
    let(:env) { {"rack.session" => {}, :user_name => "sakuro"} }

    it "returns 200" do
      response = action.call(env)

      expect(response.status).to eq(200)
    end

    it "fetches recent maps for the user" do
      action.call(env)

      expect(map_repo).to have_received(:list_with_complete_generation_by_user).with(user_id: 1, limit: 3)
    end
  end

  context "when the user does not exist" do
    let(:env) { {"rack.session" => {}, :user_name => "nobody"} }

    before { allow(user_repo).to receive(:find_by_name).with("nobody").and_return(nil) }

    it "returns 404" do
      response = action.call(env)

      expect(response.status).to eq(404)
    end
  end
end
