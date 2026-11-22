# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::Uploads::IssuePresignedPosts, :db do
  let(:operation) { Hanami.app["operations.uploads.issue_presigned_posts"] }
  let(:filenames) { ["s1zoom_4/tile_0_0.jpg", "s1zoom_4/tile_0_1.jpg"] }
  let(:upload_event_repo) { Hanami.app["repos.upload_event_repo"] }

  let(:user) { Factory[:user, name: "testuser"] }
  let(:map) { Factory[:map, user:, mapshot_map_id: "ae8ec3ab"] }
  let(:generation) do
    Factory[:generation,
      map:,
      mapshot_unique_id: "550f41a9",
      tick: 1000,
      metadata_s3_key: "testuser/maps/ae8ec3ab/550f41a9/mapshot.json"]
  end
  let!(:upload) { Factory[:upload, generation:, total_image_count: 10] }

  before { Factory[:upload_event, upload:, event_type: "pending"] }

  describe "#call" do
    it "returns presigned POST entries for all requested files" do
      result = operation.call(upload_ulid: upload.ulid, filenames:, user_id: user.id)

      expect(result).to be_success
      posts = result.value!
      expect(posts.keys).to match_array(filenames)
      expect(posts.values).to all(match(url: be_a(String), fields: be_a(Hash)))
    end

    context "when the filenames would exceed the total image count of the upload" do
      let!(:upload) { Factory[:upload, generation:, total_image_count: 3] }
      let(:key_repo) { Hanami.app["repos.upload_verification_key_repo"] }

      def tiles(range) = range.map {|x| "s1zoom_4/tile_#{x}_0.jpg" }

      it "issues the files up to the total, across several requests" do
        expect(operation.call(upload_ulid: upload.ulid, filenames: tiles(0..1), user_id: user.id)).to be_success
        expect(operation.call(upload_ulid: upload.ulid, filenames: tiles(2..2), user_id: user.id)).to be_success
        expect(key_repo.count(upload_id: upload.id)).to eq(3)
      end

      it "rejects a request that would go over the total and records nothing from it" do
        operation.call(upload_ulid: upload.ulid, filenames: tiles(0..1), user_id: user.id)

        result = operation.call(upload_ulid: upload.ulid, filenames: tiles(2..3), user_id: user.id)

        expect(result).to be_failure
        expect(result.failure).to eq(:unprocessable_entity)
        expect(key_repo.count(upload_id: upload.id)).to eq(2)
      end

      it "does not count a file that is asked for again" do
        operation.call(upload_ulid: upload.ulid, filenames: tiles(0..2), user_id: user.id)

        result = operation.call(upload_ulid: upload.ulid, filenames: tiles(0..2), user_id: user.id)

        expect(result).to be_success
        expect(key_repo.count(upload_id: upload.id)).to eq(3)
      end

      it "counts a filename repeated in one request once" do
        result = operation.call(upload_ulid: upload.ulid, filenames: tiles(0..1) + tiles(0..1), user_id: user.id)

        expect(result).to be_success
        expect(key_repo.count(upload_id: upload.id)).to eq(2)
      end
    end

    context "when the upload does not exist" do
      it "returns a not_found failure" do
        result = operation.call(upload_ulid: "nonexistent", filenames:, user_id: user.id)

        expect(result).to be_failure
        expect(result.failure).to eq(:not_found)
      end
    end

    context "when the upload belongs to another user" do
      let(:other_user) { Factory[:user, name: "otheruser"] }

      it "returns a forbidden failure" do
        result = operation.call(upload_ulid: upload.ulid, filenames:, user_id: other_user.id)

        expect(result).to be_failure
        expect(result.failure).to eq(:forbidden)
      end
    end

    context "when the upload is not pending" do
      # +1 ensures occurred_at is strictly after the pending event created in the outer before,
      # avoiding non-deterministic ordering when both timestamps fall within the same microsecond.
      before { upload_event_repo.create(upload_id: upload.id, event_type: "complete", occurred_at: Time.now + 1) }

      it "returns an unprocessable failure" do
        result = operation.call(upload_ulid: upload.ulid, filenames:, user_id: user.id)

        expect(result).to be_failure
        expect(result.failure).to eq(:unprocessable_entity)
      end
    end
  end
end
