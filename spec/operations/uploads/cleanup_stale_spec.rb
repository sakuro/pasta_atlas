# frozen_string_literal: true

require "aws-sdk-sqs"

RSpec.describe PastaAtlas::Operations::Uploads::CleanupStale do
  let(:generation_repo) { instance_double(PastaAtlas::Repos::GenerationRepo, delete_by_id: 1) }
  let(:upload_repo) { instance_double(PastaAtlas::Repos::UploadRepo) }
  let(:settings) { double("Settings", stale_upload_days: 7, sqs_s3_cleanup_queue_url: "https://sqs.example.com/queue") }
  let(:sqs_client) { instance_double(Aws::SQS::Client, send_message: nil) }
  let(:operation) { PastaAtlas::Operations::Uploads::CleanupStale.new(generation_repo:, upload_repo:, settings:, sqs_client:) }
  let(:now) { Time.utc(2026, 11, 20, 12) }
  let(:row) { PastaAtlas::Values::StaleUpload[generation_id: 10, user_name: "sakuro", mapshot_map_id: "ae8ec3ab", mapshot_unique_id: "550f41a9"] }

  before { allow(upload_repo).to receive(:find_stale_incomplete).and_return([row]) }

  it "looks for uploads without activity for the configured number of days" do
    operation.call(now:)

    expect(upload_repo).to have_received(:find_stale_incomplete).with(before: Time.utc(2026, 11, 13, 12))
  end

  it "queues the S3 prefix of the generation, then deletes the generation" do
    operation.call(now:)

    expect(sqs_client).to have_received(:send_message)
      .with(queue_url: "https://sqs.example.com/queue", message_body: "sakuro/maps/ae8ec3ab/550f41a9/").ordered
    expect(generation_repo).to have_received(:delete_by_id).with(10).ordered
  end

  it "reports what it found and deleted" do
    expect(operation.call(now:).value!).to eq(found: 1, deleted: 1, failed: 0)
  end

  context "when the prefix cannot be queued" do
    before { allow(sqs_client).to receive(:send_message).and_raise(Aws::SQS::Errors::ServiceError.new(nil, "unavailable")) }

    it "keeps the generation so that the next run tries again" do
      operation.call(now:)

      expect(generation_repo).not_to have_received(:delete_by_id)
    end

    it "reports the failure" do
      expect(operation.call(now:).value!).to eq(found: 1, deleted: 0, failed: 1)
    end
  end
end
