# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::Uploads::Update, :db do
  let(:update_status) { instance_double(PastaAtlas::Operations::Uploads::UpdateStatus) }
  let(:action) { PastaAtlas::Actions::Uploads::Update.new(update_status:) }

  let(:session) { {"rack.session" => {"user_id" => 1}} }
  let(:action_params) { {ulid: "01UPLOAD", status: "complete"} }

  context "when not authenticated" do
    it "returns 401" do
      response = action.call({"rack.session" => {}}.merge(action_params))

      expect(response.status).to eq(401)
    end
  end

  context "when authenticated" do
    context "when the operation succeeds" do
      let(:completed_at) { Time.new(2025, 1, 1, 0, 0, 0, "+00:00") }
      let(:upload) { double("Upload", ulid: "01UPLOAD", status: "complete", completed_at:) }

      before { allow(update_status).to receive(:call).and_return(Success(upload)) }

      it "returns 200 with updated upload data" do
        response = action.call(session.merge(action_params))

        expect(response.status).to eq(200)
        body = JSON.parse(response.body.join)
        expect(body).to include("ulid" => "01UPLOAD", "status" => "complete", "completed_at" => completed_at.iso8601)
      end
    end

    context "when the upload is not found" do
      before { allow(update_status).to receive(:call).and_return(Failure(:not_found)) }

      it "returns 404" do
        response = action.call(session.merge(action_params))

        expect(response.status).to eq(404)
      end
    end
  end
end
