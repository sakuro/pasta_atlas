# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::Maps::Lookup do
  let(:find_map) { instance_double(PastaAtlas::Operations::Maps::FindByMapshotId) }
  let(:user_repo) { instance_double(PastaAtlas::Repos::UserRepo) }
  let(:action) { PastaAtlas::Actions::Maps::Lookup.new(find_map:, user_repo:) }

  let(:session) { {"rack.session" => {"user_id" => 1}} }
  let(:action_params) { {mapshot_map_id: "ae8ec3ab"} }

  context "when the map is found" do
    let(:map) { double("Map", name: "My Custom Map") }

    before do
      allow(find_map).to receive(:call).and_return(Success(map))
    end

    it "returns 200 with the map name" do
      response = action.call(session.merge(action_params))

      expect(response.status).to eq(200)
      body = JSON.parse(response.body.join)
      expect(body).to include("name" => "My Custom Map")
    end
  end

  context "when the map has no custom name" do
    let(:map) { double("Map", name: nil) }

    before do
      allow(find_map).to receive(:call).and_return(Success(map))
    end

    it "returns 200 with null name" do
      response = action.call(session.merge(action_params))

      expect(response.status).to eq(200)
      body = JSON.parse(response.body.join)
      expect(body).to include("name" => nil)
    end
  end

  context "when the map is not found" do
    before { allow(find_map).to receive(:call).and_return(Failure(:not_found)) }

    it "returns 404" do
      response = action.call(session.merge(action_params))

      expect(response.status).to eq(404)
    end
  end

  context "when no session" do
    let(:guest_user) { double("User", id: 99) }

    before do
      allow(user_repo).to receive(:find_by_name).with("guest").and_return(guest_user)
      allow(find_map).to receive(:call).and_return(Failure(:not_found))
    end

    it "uses the guest user" do
      action.call({"rack.session" => {}}.merge(action_params))

      expect(find_map).to have_received(:call).with(hash_including(user_id: 99))
    end
  end
end
