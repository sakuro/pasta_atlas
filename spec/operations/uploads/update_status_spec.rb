# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::Uploads::UpdateStatus, :db do
  let(:operation) { Hanami.app["operations.uploads.update_status"] }
  let(:generation_repo) { Hanami.app["repos.generation_repo"] }
  let(:map_repo) { Hanami.app["repos.map_repo"] }
  let(:user_repo) { Hanami.app["repos.user_repo"] }

  let!(:upload) { Factory[:upload] }
  let(:generation) { generation_repo.find_by_id(upload.generation_id) }
  let(:map) { map_repo.find_by_id(generation.map_id) }
  let(:user) { user_repo.find_by_id(map.user_id) }

  describe "#call" do
    context "when updating to complete" do
      context "when all files are verified" do
        before do
          5.times {|i| Factory[:upload_verification_key, upload:, s3_key: "user/maps/abc/def/s0zoom_4/tile_#{i}_0.jpg", verified_at: Time.now] }
        end

        it "sets completed_at and returns the updated upload" do
          result = operation.call(upload_ulid: upload.ulid, status: "complete", user_id: user.id)

          expect(result).to be_success
          updated = result.value!
          expect(updated.status).to eq("complete")
          expect(updated.completed_at).not_to be_nil
        end
      end

      context "when not all files are verified" do
        it "returns an incomplete failure" do
          result = operation.call(upload_ulid: upload.ulid, status: "complete", user_id: user.id)

          expect(result).to be_failure
          expect(result.failure).to eq(:incomplete)
        end
      end
    end

    context "when updating to failed" do
      it "updates the status without setting completed_at" do
        result = operation.call(upload_ulid: upload.ulid, status: "failed", user_id: user.id)

        expect(result).to be_success
        updated = result.value!
        expect(updated.status).to eq("failed")
        expect(updated.completed_at).to be_nil
      end
    end

    context "when the upload belongs to another user" do
      let(:other_user) { Factory[:user] }

      it "returns a forbidden failure" do
        result = operation.call(upload_ulid: upload.ulid, status: "complete", user_id: other_user.id)

        expect(result).to be_failure
        expect(result.failure).to eq(:forbidden)
      end
    end

    context "when the upload does not exist" do
      it "returns a not_found failure" do
        result = operation.call(upload_ulid: "nonexistent", status: "complete", user_id: user.id)

        expect(result).to be_failure
        expect(result.failure).to eq(:not_found)
      end
    end
  end
end
