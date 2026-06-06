# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::Uploads::Create, :db do
  let(:operation) { Hanami.app["operations.uploads.create"] }
  let(:map_repo) { Hanami.app["repos.map_repo"] }
  let(:generation_repo) { Hanami.app["repos.generation_repo"] }
  let(:s3_client) { Hanami.app["s3.client"] }

  let(:user) { Factory[:user, name: "testuser"] }
  let(:metadata) { {map_id: "ae8ec3ab", unique_id: "550f41a9", tick: "1000"} }

  describe "#call" do
    context "when no generation exists" do
      it "creates a generation and pending upload" do
        result = operation.call(user_id: user.id, metadata:, total_image_count: 5)

        expect(result).to be_success
        upload = result.value![:upload]
        expect(upload.status).to eq("pending")
        expect(upload.total_image_count).to eq(5)
      end

      it "does not set expires_at for a regular user" do
        operation.call(user_id: user.id, metadata:, total_image_count: 5)

        generation = generation_repo.find_with_upload(
          map_id: map_repo.find_or_create_by_user_and_mapshot_id(
            user_id: user.id, mapshot_map_id: metadata[:map_id]
          ).id,
          mapshot_unique_id: metadata[:unique_id]
        )
        expect(generation.expires_at).to be_nil
      end
    end

    context "when uploading as a guest user" do
      let(:user) { Hanami.app["repos.user_repo"].find_by_name("guest") }

      it "sets expires_at approximately 2 days from now" do
        operation.call(user_id: user.id, metadata:, total_image_count: 5)

        generation = generation_repo.find_with_upload(
          map_id: map_repo.find_or_create_by_user_and_mapshot_id(
            user_id: user.id, mapshot_map_id: metadata[:map_id]
          ).id,
          mapshot_unique_id: metadata[:unique_id]
        )
        expect(generation.expires_at).to be_within(60).of(Time.now + (2 * 86400))
      end
    end

    context "when a pending upload already exists for the generation" do
      let(:map) { Factory[:map, user:, mapshot_map_id: "ae8ec3ab"] }
      let(:generation) do
        Factory[:generation,
          map:,
          mapshot_unique_id: "550f41a9",
          tick: 1000,
          metadata_s3_key: "testuser/maps/ae8ec3ab/550f41a9/mapshot.json"]
      end
      let!(:existing_upload) { Factory[:upload, generation:, total_image_count: 3] }

      before { Factory[:upload_event, upload: existing_upload, event_type: "pending"] }

      it "returns the existing upload" do
        result = operation.call(user_id: user.id, metadata:, total_image_count: 5)

        expect(result).to be_success
        expect(result.value![:upload].id).to eq(existing_upload.id)
      end
    end

    context "when a complete upload already exists for the generation" do
      let(:map) { Factory[:map, user:, mapshot_map_id: "ae8ec3ab"] }
      let(:generation) do
        Factory[:generation,
          map:,
          mapshot_unique_id: "550f41a9",
          tick: 1000,
          metadata_s3_key: "testuser/maps/ae8ec3ab/550f41a9/mapshot.json"]
      end

      before do
        upload = Factory[:upload, generation:, total_image_count: 5]
        Factory[:upload_event, upload:, event_type: "pending"]
        Factory[:upload_event, upload:, event_type: "complete"]
      end

      it "returns a conflict failure" do
        result = operation.call(user_id: user.id, metadata:, total_image_count: 5)

        expect(result).to be_failure
        expect(result.failure).to eq(:conflict)
      end
    end

    context "when all generations for the map are expired" do
      let(:map) { Factory[:map, user:, mapshot_map_id: "ae8ec3ab"] }

      before do
        Factory[:generation, :expired, map:, mapshot_unique_id: "prev_gen"]
      end

      it "returns a gone failure" do
        result = operation.call(user_id: user.id, metadata:, total_image_count: 5)

        expect(result).to be_failure
        expect(result.failure).to eq(:gone)
      end
    end

    context "when S3 write fails" do
      before do
        allow(s3_client).to receive(:put_object)
          .and_raise(Aws::S3::Errors::ServiceError.new(nil, "stub"))
      end

      it "returns an S3 error failure and rolls back the generation" do
        result = operation.call(user_id: user.id, metadata:, total_image_count: 5)

        expect(result).to be_failure
        expect(result.failure).to eq(:s3_error)

        map = map_repo.find_or_create_by_user_and_mapshot_id(
          user_id: user.id, mapshot_map_id: metadata[:map_id]
        )
        expect(
          generation_repo.find_with_upload(
            map_id: map.id, mapshot_unique_id: metadata[:unique_id]
          )
        ).to be_nil
      end
    end
  end
end
