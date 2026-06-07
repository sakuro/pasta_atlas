# frozen_string_literal: true

require "aws-sdk-s3"
require "aws-sdk-sqs"

RSpec.describe PastaAtlas::Operations::Uploads::VerifyBatch do
  let(:generation_repo) { instance_double(PastaAtlas::Repos::GenerationRepo) }
  let(:map_repo) { instance_double(PastaAtlas::Repos::MapRepo) }
  let(:upload_repo) { instance_double(PastaAtlas::Repos::UploadRepo) }
  let(:upload_verification_key_repo) { instance_double(PastaAtlas::Repos::UploadVerificationKeyRepo) }
  let(:user_repo) { instance_double(PastaAtlas::Repos::UserRepo) }
  let(:settings) do
    double(
      "Settings",
      s3_bucket: "test-bucket",
      sqs_s3_cleanup_queue_url: "https://sqs.example.com/queue"
    )
  end
  let(:s3_client) { instance_double(Aws::S3::Client) }
  let(:sqs_client) { instance_double(Aws::SQS::Client) }
  let(:operation) do
    PastaAtlas::Operations::Uploads::VerifyBatch.new(
      generation_repo:,
      map_repo:,
      upload_repo:,
      upload_verification_key_repo:,
      user_repo:,
      settings:,
      s3_client:,
      sqs_client:
    )
  end

  let(:upload) { double("Upload", id: 1, generation_id: 10) }
  let(:generation) { double("Generation", id: 10, map_id: 20, mapshot_unique_id: "550f41a9") }
  let(:map) { double("Map", id: 20, user_id: 30, mapshot_map_id: "ae8ec3ab") }
  let(:user) { double("User", id: 30, name: "testuser") }
  let(:filenames) { ["s0zoom_4/tile_0_0.jpg", "s0zoom_4/tile_0_1.jpg"] }

  before do
    allow(generation_repo).to receive(:find_by_id).with(10).and_return(generation)
    allow(map_repo).to receive(:find_by_id).with(20).and_return(map)
    allow(user_repo).to receive(:find_by_id).with(30).and_return(user)
  end

  describe "#call" do
    context "when all files exist in S3" do
      let(:head_response) { double("HeadResponse", content_length: 1024) }

      before do
        allow(s3_client).to receive(:head_object).and_return(head_response)
        allow(upload_verification_key_repo).to receive(:mark_verified_batch)
        allow(upload_repo).to receive(:accumulate_verified_bytes)
      end

      it "returns verified_bytes for the batch" do
        result = operation.call(upload:, filenames:)

        expect(result).to be_success
        expect(result.value!).to eq({verified_bytes: 2048})
      end

      it "marks keys as verified" do
        operation.call(upload:, filenames:)

        expect(upload_verification_key_repo).to have_received(:mark_verified_batch).with(
          upload_id: 1,
          results: [
            {s3_key: "testuser/maps/ae8ec3ab/550f41a9/s0zoom_4/tile_0_0.jpg", size_bytes: 1024},
            {s3_key: "testuser/maps/ae8ec3ab/550f41a9/s0zoom_4/tile_0_1.jpg", size_bytes: 1024}
          ]
        )
      end

      it "accumulates bytes on the upload" do
        operation.call(upload:, filenames:)

        expect(upload_repo).to have_received(:accumulate_verified_bytes).with(id: 1, bytes: 2048)
      end
    end

    context "when some files are missing in S3" do
      before do
        allow(s3_client).to receive(:head_object)
          .with(bucket: "test-bucket", key: "testuser/maps/ae8ec3ab/550f41a9/s0zoom_4/tile_0_0.jpg")
          .and_return(double("HeadResponse", content_length: 1024))
        allow(s3_client).to receive(:head_object)
          .with(bucket: "test-bucket", key: "testuser/maps/ae8ec3ab/550f41a9/s0zoom_4/tile_0_1.jpg")
          .and_raise(Aws::S3::Errors::NotFound.new(nil, "Not Found"))
        allow(sqs_client).to receive(:send_message)
        allow(generation_repo).to receive(:delete_by_id)
      end

      it "returns a verification_failed failure" do
        result = operation.call(upload:, filenames:)

        expect(result).to be_failure
        expect(result.failure).to eq(:verification_failed)
      end

      it "schedules S3 cleanup before deleting the generation" do
        delete_order = []
        allow(sqs_client).to receive(:send_message) { delete_order << :sqs }
        allow(generation_repo).to receive(:delete_by_id) { delete_order << :db }

        operation.call(upload:, filenames:)

        expect(delete_order).to eq(%i[sqs db])
      end

      it "schedules S3 cleanup with the generation prefix" do
        operation.call(upload:, filenames:)

        expect(sqs_client).to have_received(:send_message).with(
          queue_url: "https://sqs.example.com/queue",
          message_body: "testuser/maps/ae8ec3ab/550f41a9/"
        )
      end

      it "deletes the generation from DB" do
        operation.call(upload:, filenames:)

        expect(generation_repo).to have_received(:delete_by_id).with(10)
      end

      context "when SQS send fails" do
        before do
          allow(sqs_client).to receive(:send_message)
            .and_raise(Aws::SQS::Errors::ServiceError.new(nil, "error"))
        end

        it "returns an sqs_error failure" do
          result = operation.call(upload:, filenames:)

          expect(result).to be_failure
          expect(result.failure).to eq(:sqs_error)
        end

        it "does not delete the generation" do
          operation.call(upload:, filenames:)

          expect(generation_repo).not_to have_received(:delete_by_id)
        end
      end
    end
  end
end
