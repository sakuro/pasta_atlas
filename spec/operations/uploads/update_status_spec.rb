# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::Uploads::UpdateStatus, :db do
  let(:operation) { Hanami.app["operations.uploads.update_status"] }
  let(:generation_repo) { Hanami.app["repos.generation_repo"] }
  let(:map_repo) { Hanami.app["repos.map_repo"] }
  let(:user_repo) { Hanami.app["repos.user_repo"] }

  let!(:upload) { Factory[:upload] }
  let(:generation) { generation_repo.find_by_id!(upload.generation_id) }
  let(:map) { map_repo.find_by_id!(generation.map_id) }
  let(:user) { user_repo.find_by_id!(map.user_id) }

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

      context "when computing the storage size of the generation" do
        let!(:upload) { Factory[:upload, total_image_count: 2, metadata_bytes: 300] }
        let(:prefix) { "#{user.name}/maps/#{map.mapshot_map_id}/#{generation.mapshot_unique_id}/" }
        let(:tiles) { ["s0zoom_4/tile_0_0.jpg", "s0zoom_4/tile_0_1.jpg"] }
        let(:s3_client) { Aws::S3::Client.new(stub_responses: {head_object: {content_length: 1000}}) }
        let(:verify_batch) { PastaAtlas::Operations::Uploads::VerifyBatch.new(s3_client:) }
        let(:key_repo) { Hanami.app["repos.upload_verification_key_repo"] }
        let(:upload_repo) { Hanami.app["repos.upload_repo"] }

        def complete_and_read_storage_bytes
          operation.call(upload_ulid: upload.ulid, status: "complete", user_id: user.id)
          generation_repo.find_by_id!(upload.generation_id).storage_bytes
        end

        def verify(filenames) = verify_batch.call(upload: upload_repo.find_by_ulid(upload.ulid), filenames:)

        before do
          Factory[:upload_event, upload:, event_type: "pending"]
          key_repo.create_many(upload_id: upload.id, s3_keys: tiles.map {|tile| "#{prefix}#{tile}" })
        end

        it "stores the metadata bytes plus the sizes of the verified keys" do
          verify(tiles)

          expect(complete_and_read_storage_bytes).to eq(300 + 2000)
        end

        it "does not count a filename that presigned_posts did not issue" do
          verify(tiles + ["mapshot.json"])

          expect(complete_and_read_storage_bytes).to eq(300 + 2000)
        end

        it "counts a file verified twice once" do
          verify(tiles)
          verify(tiles.take(1))

          expect(complete_and_read_storage_bytes).to eq(300 + 2000)
        end

        it "does not count the keys of another upload" do
          Factory[:upload_verification_key, size_bytes: 5000]
          verify(tiles)

          expect(complete_and_read_storage_bytes).to eq(300 + 2000)
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
