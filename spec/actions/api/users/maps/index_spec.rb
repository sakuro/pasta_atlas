# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::API::Users::Maps::Index do
  let(:find_by_name) { instance_double(PastaAtlas::Operations::User::FindByName) }
  let(:list_recent_maps) { instance_double(PastaAtlas::Operations::Maps::ListRecentByUser) }
  let(:load_profile) { instance_double(PastaAtlas::Operations::User::Profile::Load) }
  let(:action) { PastaAtlas::Actions::API::Users::Maps::Index.new(find_by_name:, list_recent_maps:, load_profile:) }

  let(:user) { double("User", id: 1, name: "sakuro", guest?: false) }
  let(:user_info) { PastaAtlas::Values::UserInfo[name: "sakuro", display_name: "Sakuro", avatar_url: nil] }
  let(:map_info) do
    double(
      "MapInfo",
      ulid: "01MAP1",
      display_name: "Map 1",
      user_info:,
      thumbnail_url: "https://cdn.example.com/thumb.jpg",
      metadata_url: "https://cdn.example.com/mapshot.json",
      updated_at: Time.new(2024, 1, 1)
    )
  end

  context "when the user does not exist" do
    let(:env) { {"rack.session" => {}, :user_name => "nobody"} }

    before { allow(find_by_name).to receive(:call).with(user_name: "nobody").and_return(Failure(:not_found)) }

    it "returns 404" do
      response = action.call(env)

      expect(response.status).to eq(404)
    end
  end

  context "when the requested user is the guest account" do
    let(:guest) { double("User", id: 999, name: "guest", guest?: true) }
    let(:env) { {"rack.session" => {}, :user_name => "guest"} }

    before { allow(find_by_name).to receive(:call).with(user_name: "guest").and_return(Success(guest)) }

    it "returns 404" do
      response = action.call(env)

      expect(response.status).to eq(404)
    end
  end

  context "when the user exists" do
    let(:env) { {"rack.session" => {}, :user_name => "sakuro"} }

    before do
      allow(find_by_name).to receive(:call).with(user_name: "sakuro").and_return(Success(user))
      allow(load_profile).to receive(:call).with(user_id: 1).and_return(Success({display_name: "Sakuro", avatar_url: nil}))
      allow(list_recent_maps).to receive(:call).with(user_id: 1, user_info: anything).and_return(Success([map_info]))
    end

    it "returns 200 with maps JSON" do
      response = action.call(env)

      expect(response.status).to eq(200)
      body = JSON.parse(response.body.join)
      expect(body["maps"].length).to eq(1)
      expect(body["maps"].first).to include(
        "ulid" => "01MAP1",
        "display_name" => "Map 1",
        "user_name" => "sakuro",
        "author_display_name" => "Sakuro"
      )
    end

    context "when the user has no maps" do
      before { allow(list_recent_maps).to receive(:call).with(user_id: 1, user_info: anything).and_return(Success([])) }

      it "returns an empty maps array" do
        response = action.call(env)

        body = JSON.parse(response.body.join)
        expect(body["maps"]).to eq([])
      end
    end
  end
end
