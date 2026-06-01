# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::API::Users::Maps::Show do
  let(:find_by_name) { instance_double(PastaAtlas::Operations::User::FindByName) }
  let(:show_map) { instance_double(PastaAtlas::Operations::Maps::Show) }
  let(:settings) { double("Settings", cloudfront_base_url: "https://cdn.example.com") }
  let(:action) { PastaAtlas::Actions::API::Users::Maps::Show.new(settings:, find_by_name:, show_map:) }

  let(:action_params) { {user_name: "sakuro", ulid: "01MAP"} }
  let(:user) { double("User", id: 1, name: "sakuro") }

  context "when the user is not found" do
    before { allow(find_by_name).to receive(:call).with(user_name: "sakuro").and_return(Failure(:not_found)) }

    it "returns 404" do
      response = action.call(action_params)

      expect(response.status).to eq(404)
    end
  end

  context "when the user exists" do
    before { allow(find_by_name).to receive(:call).with(user_name: "sakuro").and_return(Success(user)) }

    context "when the map is not found" do
      before { allow(show_map).to receive(:call).with(ulid: "01MAP").and_return(Failure(:not_found)) }

      it "returns 404" do
        response = action.call(action_params)

        expect(response.status).to eq(404)
      end
    end

    context "when the map belongs to a different user" do
      let(:map) { double("Map", ulid: "01MAP", display_name: "my-save", user_id: 99) }
      let(:map_user) { double("User", name: "other") }
      let(:profile) { double("UserProfile", display_name: "Other", avatar_s3_key: nil) }
      let(:updated_at) { Time.new(2024, 1, 15, 12, 0, 0, "+00:00") }
      let(:generation) { double("Generation", ulid: "01GEN", tick: 1000, metadata_s3_key: "ae8ec3ab/550f41a9/mapshot.json") }

      before do
        allow(show_map).to receive(:call).with(ulid: "01MAP").and_return(
          Success({map:, user: map_user, profile:, updated_at:, generations: [generation]})
        )
      end

      it "returns 404" do
        response = action.call(action_params)

        expect(response.status).to eq(404)
      end
    end

    context "when the map exists and belongs to the user" do
      let(:map) { double("Map", ulid: "01MAP", display_name: "my-save", user_id: 1) }
      let(:profile) { double("UserProfile", display_name: "Sakuro", avatar_s3_key: nil) }
      let(:updated_at) { Time.new(2024, 1, 15, 12, 0, 0, "+00:00") }
      let(:generation) { double("Generation", ulid: "01GEN", tick: 1000, metadata_s3_key: "ae8ec3ab/550f41a9/mapshot.json") }

      before do
        allow(show_map).to receive(:call).with(ulid: "01MAP").and_return(
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
  end
end
