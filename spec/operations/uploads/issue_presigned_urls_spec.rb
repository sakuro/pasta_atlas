# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::Uploads::IssuePresignedUrls, :db do
  let(:operation) { Hanami.app["operations.uploads.issue_presigned_urls"] }
  let(:filenames) { ["s1zoom_4/tile_0_0.jpg", "s1zoom_4/tile_0_1.jpg"] }
  let(:upload_event_repo) { Hanami.app["repos.upload_event_repo"] }
  let(:s3_client) { Hanami.app["s3.client"] }

  let(:user) { Factory[:user, name: "testuser"] }
  let(:map) { Factory[:map, user:, mapshot_map_id: "ae8ec3ab"] }
  let(:generation) do
    Factory[:generation,
      map:,
      mapshot_unique_id: "550f41a9",
      tick: 1000,
      metadata_s3_key: "testuser/ae8ec3ab/550f41a9/mapshot.json"]
  end
  let!(:upload) { Factory[:upload, generation:, total_image_count: 10] }

  before { Factory[:upload_event, upload:, event_type: "pending"] }

  describe "#call" do
    before { s3_client.stub_responses(:list_objects_v2, {contents: []}) }

    context "when no files exist in S3" do
      it "returns presigned URLs for all requested files" do
        result = operation.call(upload_ulid: upload.ulid, filenames:)

        expect(result).to be_success
        urls = result.value!
        expect(urls.keys).to match_array(filenames)
        expect(urls.values).to all(be_a(String))
      end
    end

    context "when some files already exist in S3" do
      before do
        s3_client.stub_responses(:list_objects_v2, {
          contents: [{key: "testuser/ae8ec3ab/550f41a9/s1zoom_4/tile_0_0.jpg"}]
        })
      end

      it "excludes already-uploaded files from presigned URLs" do
        result = operation.call(upload_ulid: upload.ulid, filenames:)

        expect(result).to be_success
        expect(result.value!.keys).to contain_exactly("s1zoom_4/tile_0_1.jpg")
      end
    end

    context "when the upload does not exist" do
      it "returns a not_found failure" do
        result = operation.call(upload_ulid: "nonexistent", filenames:)

        expect(result).to be_failure
        expect(result.failure).to eq(:not_found)
      end
    end

    context "when filenames contain invalid entries" do
      it "returns an unprocessable_entity failure for a path traversal attempt" do
        result = operation.call(upload_ulid: upload.ulid, filenames: ["../../other/file.jpg"])
        expect(result).to be_failure
        expect(result.failure).to eq(:unprocessable_entity)
      end

      it "returns an unprocessable_entity failure for a filename without the zoom directory" do
        result = operation.call(upload_ulid: upload.ulid, filenames: ["tile_0_0.jpg"])
        expect(result).to be_failure
        expect(result.failure).to eq(:unprocessable_entity)
      end

      it "returns an unprocessable_entity failure for mapshot.json" do
        result = operation.call(upload_ulid: upload.ulid, filenames: ["mapshot.json"])
        expect(result).to be_failure
        expect(result.failure).to eq(:unprocessable_entity)
      end

      it "returns an unprocessable_entity failure when filenames is not an array" do
        result = operation.call(upload_ulid: upload.ulid, filenames: "s1zoom_4/tile_0_0.jpg")
        expect(result).to be_failure
        expect(result.failure).to eq(:unprocessable_entity)
      end
    end

    context "when the upload is not pending" do
      # +1 ensures occurred_at is strictly after the pending event created in the outer before,
      # avoiding non-deterministic ordering when both timestamps fall within the same microsecond.
      before { upload_event_repo.create(upload_id: upload.id, event_type: "complete", occurred_at: Time.now + 1) }

      it "returns an unprocessable failure" do
        result = operation.call(upload_ulid: upload.ulid, filenames:)

        expect(result).to be_failure
        expect(result.failure).to eq(:unprocessable_entity)
      end
    end
  end
end
