# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::Uploads::UpdateStatus, :db do
  let(:operation) { Hanami.app["operations.uploads.update_status"] }
  let!(:upload) { Factory[:upload] }

  describe "#call" do
    context "when updating to complete" do
      it "sets completed_at and returns the updated upload" do
        result = operation.call(upload_ulid: upload.ulid, status: "complete")

        expect(result).to be_success
        updated = result.value!
        expect(updated.status).to eq("complete")
        expect(updated.completed_at).not_to be_nil
      end
    end

    context "when updating to failed" do
      it "updates the status without setting completed_at" do
        result = operation.call(upload_ulid: upload.ulid, status: "failed")

        expect(result).to be_success
        updated = result.value!
        expect(updated.status).to eq("failed")
        expect(updated.completed_at).to be_nil
      end
    end

    context "when the upload does not exist" do
      it "returns a not_found failure" do
        result = operation.call(upload_ulid: "nonexistent", status: "complete")

        expect(result).to be_failure
        expect(result.failure).to eq(:not_found)
      end
    end
  end
end
