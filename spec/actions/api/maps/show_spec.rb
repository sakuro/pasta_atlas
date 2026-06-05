# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::API::Maps::Show do
  let(:show_map) { instance_double(PastaAtlas::Operations::Maps::Show) }
  let(:action) { PastaAtlas::Actions::API::Maps::Show.new(show_map:) }

  let(:action_params) { {ulid: "01MAP"} }

  context "when the map is found" do
    let(:updated_at) { Time.new(2024, 1, 15, 12, 0, 0, "+00:00") }
    let(:user_info) { PastaAtlas::Values::UserInfo[name: "sakuro", display_name: "Sakuro", avatar_url: nil] }
    let(:map_info) { PastaAtlas::Values::MapInfo[ulid: "01MAP", display_name: "my-save", user_info:, thumbnail_url: nil, metadata_url: nil, updated_at:] }
    let(:generations) { [{ulid: "01GEN", tick: 1000, metadata_url: "https://cdn.example.com/ae8ec3ab/550f41a9/mapshot.json"}] }

    before do
      allow(show_map).to receive(:call).and_return(
        Success({map_info:, generations:})
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
