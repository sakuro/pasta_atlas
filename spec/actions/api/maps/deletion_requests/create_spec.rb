# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::API::Maps::DeletionRequests::Create do
  let(:guest) { double("User", id: 0) }
  let(:request_deletion) { instance_double(PastaAtlas::Operations::Maps::RequestDeletion) }
  let(:action) { PastaAtlas::Actions::API::Maps::DeletionRequests::Create.new(guest:, request_deletion:) }

  let(:action_params) { {"rack.session" => {"user_id" => 1}, :ulid => "01MAP"} }

  context "when the deletion request succeeds" do
    let(:map) { double("Map", ulid: "01MAP") }

    before do
      allow(request_deletion).to receive(:call)
        .with(ulid: "01MAP", current_user_id: 1)
        .and_return(Success(map))
    end

    it "redirects to /" do
      response = action.call(action_params)

      expect(response.status).to eq(302)
      expect(response.headers["Location"]).to eq("/")
    end
  end

  context "when not logged in" do
    before do
      allow(request_deletion).to receive(:call)
        .with(ulid: "01MAP", current_user_id: 0)
        .and_return(Failure(:forbidden))
    end

    it "returns 403" do
      response = action.call({ulid: "01MAP"})

      expect(response.status).to eq(403)
    end
  end

  context "when user does not own the map" do
    before do
      allow(request_deletion).to receive(:call)
        .with(ulid: "01MAP", current_user_id: 1)
        .and_return(Failure(:forbidden))
    end

    it "returns 403" do
      response = action.call(action_params)

      expect(response.status).to eq(403)
    end
  end

  context "when map is not found" do
    before do
      allow(request_deletion).to receive(:call)
        .with(ulid: "01MAP", current_user_id: 1)
        .and_return(Failure(:not_found))
    end

    it "returns 404" do
      response = action.call(action_params)

      expect(response.status).to eq(404)
    end
  end
end
