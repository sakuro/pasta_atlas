# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::Spa::MapViewer do
  let(:find_by_name) { instance_double(PastaAtlas::Operations::User::FindByName) }
  let(:find_map) { instance_double(PastaAtlas::Operations::Maps::FindByUlid) }
  let(:action) { PastaAtlas::Actions::Spa::MapViewer.new(find_by_name:, find_map:) }

  let(:ulid) { "01JXXXXXXXXXXXXXXXXXXXX" }

  context "when the user does not exist" do
    before { allow(find_by_name).to receive(:call).with(user_name: "nobody").and_return(Failure(:not_found)) }

    it "returns 404" do
      response = action.call({user_name: "nobody", map_ulid: ulid})

      expect(response.status).to eq(404)
    end
  end

  context "when the user exists" do
    let(:user) { double("User", id: 1) }

    before { allow(find_by_name).to receive(:call).with(user_name: "sakuro").and_return(Success(user)) }

    context "when the map exists and belongs to the user" do
      let(:map) { double("Map") }

      before { allow(find_map).to receive(:call).with(ulid:, user_id: 1).and_return(Success(map)) }

      it "returns 200" do
        response = action.call({user_name: "sakuro", map_ulid: ulid})

        expect(response.status).to eq(200)
      end
    end

    context "when the map is not found" do
      before { allow(find_map).to receive(:call).with(ulid:, user_id: 1).and_return(Failure(:not_found)) }

      it "returns 404" do
        response = action.call({user_name: "sakuro", map_ulid: ulid})

        expect(response.status).to eq(404)
      end
    end
  end
end
