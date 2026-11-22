# frozen_string_literal: true

require "aws-sdk-sqs"

RSpec.describe PastaAtlas::Operations::User::Avatar::ScheduleCleanup do
  let(:settings) { double("Settings", sqs_s3_cleanup_queue_url: "https://sqs.example.com/queue") }
  let(:sqs_client) { instance_double(Aws::SQS::Client) }
  let(:operation) { PastaAtlas::Operations::User::Avatar::ScheduleCleanup.new(settings:, sqs_client:) }

  describe "#call" do
    it "sends the key to the S3 cleanup queue" do
      allow(sqs_client).to receive(:send_message)

      result = operation.call(s3_key: "alice/avatar/old.jpg")

      expect(result).to be_success
      expect(sqs_client).to have_received(:send_message).with(
        queue_url: "https://sqs.example.com/queue",
        message_body: "alice/avatar/old.jpg"
      )
    end

    it "returns Failure(:enqueue_failed) when SQS raises a service error" do
      allow(sqs_client).to receive(:send_message)
        .and_raise(Aws::SQS::Errors::ServiceError.new(nil, "error"))

      result = operation.call(s3_key: "alice/avatar/old.jpg")

      expect(result).to be_failure
      expect(result.failure).to eq(:enqueue_failed)
    end
  end
end
