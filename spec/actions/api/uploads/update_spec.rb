# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::API::Uploads::Update, :db do
  let(:update_status) { instance_double(PastaAtlas::Operations::Uploads::UpdateStatus) }
  let(:guest) { double("User", id: 99) }
  let(:action) { PastaAtlas::Actions::API::Uploads::Update.new(update_status:, guest:) }

  let(:session) { {"rack.session" => {"user_id" => 1}} }
  let(:action_params) { {ulid: "01UPLOAD", status: "complete"} }

  context "when no session" do
    # The guest cannot create uploads, so the ownership check of the operation rejects it.
    before do
      allow(update_status).to receive(:call).and_return(Failure(:forbidden))
    end

    it "leaves the guest to the ownership check of the operation" do
      response = action.call({"rack.session" => {}}.merge(action_params))

      expect(response.status).to eq(403)
      expect(response).to conform_to_openapi("PATCH /api/v1/uploads/{ulid}")
      expect(update_status).to have_received(:call).with(upload_ulid: "01UPLOAD", user_id: 99)
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
        expect(response).to conform_to_openapi("PATCH /api/v1/uploads/{ulid}")
        body = JSON.parse(response.body.join)
        expect(body).to include("ulid" => "01UPLOAD", "status" => "complete", "completed_at" => completed_at.iso8601)
      end
    end

    context "when the upload is not found" do
      before { allow(update_status).to receive(:call).and_return(Failure(:not_found)) }

      it "returns 404" do
        response = action.call(session.merge(action_params))

        expect(response.status).to eq(404)
        expect(response).to conform_to_openapi("PATCH /api/v1/uploads/{ulid}")
      end
    end

    context "when the status is invalid" do
      before { allow(update_status).to receive(:call) }

      it "returns 400 without calling the operation" do
        response = action.call(session.merge(action_params.merge(status: "pending")))

        expect(response.status).to eq(400)
        expect(response).to conform_to_openapi("PATCH /api/v1/uploads/{ulid}")
        expect(update_status).not_to have_received(:call)
      end
    end

    context "when the status is failed" do
      before { allow(update_status).to receive(:call) }

      it "returns 400 without calling the operation" do
        response = action.call(session.merge(action_params.merge(status: "failed")))

        expect(response.status).to eq(400)
        expect(response).to conform_to_openapi("PATCH /api/v1/uploads/{ulid}")
        expect(update_status).not_to have_received(:call)
      end
    end

    context "when not every image has been verified" do
      before { allow(update_status).to receive(:call).and_return(Failure(:incomplete)) }

      it "returns 422" do
        response = action.call(session.merge(action_params))

        expect(response.status).to eq(422)
        expect(response).to conform_to_openapi("PATCH /api/v1/uploads/{ulid}")
      end
    end

    context "when the upload failed" do
      before { allow(update_status).to receive(:call).and_return(Failure(:unprocessable_entity)) }

      it "returns 422" do
        response = action.call(session.merge(action_params))

        expect(response.status).to eq(422)
        expect(response).to conform_to_openapi("PATCH /api/v1/uploads/{ulid}")
      end
    end

    context "when the upload belongs to another user" do
      before { allow(update_status).to receive(:call).and_return(Failure(:forbidden)) }

      it "returns 403" do
        response = action.call(session.merge(action_params))

        expect(response.status).to eq(403)
        expect(response).to conform_to_openapi("PATCH /api/v1/uploads/{ulid}")
      end
    end
  end
end
