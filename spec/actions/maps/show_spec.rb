# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::Maps::Show do
  let(:show_map) { instance_double(PastaAtlas::Operations::Maps::Show) }
  let(:settings) { double("Settings", cloudfront_base_url: "https://cdn.example.com") }
  let(:action) { PastaAtlas::Actions::Maps::Show.new(settings:, show_map:) }

  let(:action_params) { {ulid: "01MAP"} }

  context "when the map is found" do
    let(:map) { double("Map", ulid: "01MAP", display_name: "my-save") }
    let(:user) { double("User", name: "sakuro") }
    let(:profile) { double("UserProfile", display_name: "Sakuro", avatar_s3_key: nil) }
    let(:updated_at) { Time.new(2024, 1, 15, 12, 0, 0, "+00:00") }
    let(:generation) do
      double("Generation", ulid: "01GEN", tick: 1000, metadata_s3_key: "ae8ec3ab/550f41a9/mapshot.json")
    end

    before do
      allow(show_map).to receive(:call).and_return(
        Success({map:, user:, profile:, updated_at:, generations: [generation]})
      )
    end

    it "returns 200 with map data" do
      response = action.call(action_params)

      expect(response.status).to eq(200)
      body = JSON.parse(response.body.join)
      expect(body).to include(
        "ulid" => "01MAP",
        "display_name" => "my-save",
        "updated_at" => "2024-01-15T12:00:00+00:00"
      )
      expect(body["owner"]).to include(
        "name" => "sakuro",
        "display_name" => "Sakuro",
        "avatar_url" => nil
      )
      expect(body["generations"].first).to include(
        "ulid" => "01GEN",
        "tick" => 1000
      )
      expect(body["generations"].first["metadata_url"]).to end_with("ae8ec3ab/550f41a9/mapshot.json")
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
