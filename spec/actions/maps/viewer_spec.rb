# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::Maps::Viewer do
  let(:show_map) { instance_double(PastaAtlas::Operations::Maps::Show) }
  let(:user_profile_repo) { instance_double(PastaAtlas::Repos::UserProfileRepo) }
  let(:settings) { double("Settings", cloudfront_base_url: "https://cdn.example.com") }
  let(:action) { PastaAtlas::Actions::Maps::Viewer.new(show_map:, user_profile_repo:, settings:) }

  let(:action_params) { {ulid: "01MAP"} }

  context "when the map is found" do
    let(:map) { double("Map", ulid: "01MAP", display_name: "My Map", user_id: 1) }
    let(:user) { double("User", id: 1, name: "sakuro") }
    let(:profile) { double("UserProfile", display_name: "Sakuro", avatar_s3_key: nil) }
    let(:generation) { double("Generation", ulid: "01GEN", tick: 1000, metadata_s3_key: "key", created_at: Time.now) }

    before do
      allow(show_map).to receive(:call).and_return(
        Success({map:, user:, generations: [generation]})
      )
      allow(user_profile_repo).to receive(:find_by_user_id).with(1).and_return(profile)
    end

    it "returns 200" do
      response = action.call(action_params)

      expect(response.status).to eq(200)
    end
  end

  context "when the map is not found" do
    before { allow(show_map).to receive(:call).and_return(Failure(:not_found)) }

    it "returns 404" do
      response = action.call(action_params)

      expect(response.status).to eq(404)
    end
  end
end
