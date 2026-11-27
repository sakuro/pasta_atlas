# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::API::Maps::UpdateName do
  let(:update_map_name) { instance_double(PastaAtlas::Operations::Maps::UpdateName) }
  let(:guest) { double("User", id: 0) }
  let(:action) { PastaAtlas::Actions::API::Maps::UpdateName.new(update_map_name:, guest:) }

  let(:env) { {"rack.session" => {"user_id" => 1}, :ulid => "01MAP", :name => "  renamed  "} }

  context "when the map is renamed" do
    before do
      allow(update_map_name).to receive(:call)
        .with(ulid: "01MAP", name: "renamed", current_user_id: 1)
        .and_return(Success(double("Map", name: "renamed")))
    end

    it "returns 200 with the new display name" do
      response = action.call(env)

      expect(response.status).to eq(200)
      expect(JSON.parse(response.body.join)).to eq("display_name" => "renamed")
      expect(response).to conform_to_openapi("PATCH /api/v1/maps/{ulid}/name")
    end
  end

  context "when the name is rejected" do
    before do
      allow(update_map_name).to receive(:call).and_return(Failure([:invalid, "error-map-name-too-long"]))
    end

    it "returns 422 with the error key" do
      response = action.call(env)

      expect(response.status).to eq(422)
      expect(JSON.parse(response.body.join)).to eq("error" => "error-map-name-too-long")
      expect(response).to conform_to_openapi("PATCH /api/v1/maps/{ulid}/name")
    end
  end

  context "when the user may not rename the map" do
    before { allow(update_map_name).to receive(:call).and_return(Failure(:forbidden)) }

    it "returns 403" do
      response = action.call(env)

      expect(response.status).to eq(403)
      expect(response).to conform_to_openapi("PATCH /api/v1/maps/{ulid}/name")
    end
  end

  context "when the map does not exist" do
    before { allow(update_map_name).to receive(:call).and_return(Failure(:not_found)) }

    it "returns 404" do
      response = action.call(env)

      expect(response.status).to eq(404)
      expect(response).to conform_to_openapi("PATCH /api/v1/maps/{ulid}/name")
    end
  end
end
