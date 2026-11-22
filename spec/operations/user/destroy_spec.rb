# frozen_string_literal: true

require "aws-sdk-sqs"

RSpec.describe PastaAtlas::Operations::User::Destroy do
  let(:map_repo) { instance_double(PastaAtlas::Repos::MapRepo) }
  let(:user_repo) { instance_double(PastaAtlas::Repos::UserRepo) }
  let(:settings) { double("Settings", sqs_s3_cleanup_queue_url: "https://sqs.example.com/queue") }
  let(:sqs_client) { instance_double(Aws::SQS::Client) }
  let(:operation) { PastaAtlas::Operations::User::Destroy.new(map_repo:, user_repo:, settings:, sqs_client:) }

  let(:user) { double("User", id: 1, name: "alice") }
  let(:map_abc) { double("Map", mapshot_map_id: "map-abc") }
  let(:map_xyz) { double("Map", mapshot_map_id: "map-xyz") }

  describe "#call" do
    context "when user owns maps" do
      before do
        allow(map_repo).to receive(:find_all_by_user_id).with(1).and_return([map_abc, map_xyz])
        allow(user_repo).to receive(:destroy).with(1)
        allow(sqs_client).to receive(:send_message)
      end

      it "destroys the user record" do
        operation.call(user:)

        expect(user_repo).to have_received(:destroy).with(1)
      end

      it "sends SQS messages for each map S3 prefix" do
        operation.call(user:)

        expect(sqs_client).to have_received(:send_message).with(
          queue_url: "https://sqs.example.com/queue",
          message_body: "alice/maps/map-abc/"
        )
        expect(sqs_client).to have_received(:send_message).with(
          queue_url: "https://sqs.example.com/queue",
          message_body: "alice/maps/map-xyz/"
        )
      end

      it "sends an SQS message for the avatar S3 prefix" do
        operation.call(user:)

        expect(sqs_client).to have_received(:send_message).with(
          queue_url: "https://sqs.example.com/queue",
          message_body: "alice/avatar/"
        )
      end

      it "returns success with the user" do
        result = operation.call(user:)

        expect(result).to be_success
        expect(result.value!).to eq(user)
      end
    end

    context "when user has no maps" do
      before do
        allow(map_repo).to receive(:find_all_by_user_id).with(1).and_return([])
        allow(user_repo).to receive(:destroy).with(1)
        allow(sqs_client).to receive(:send_message)
      end

      it "still sends SQS message for avatar prefix" do
        operation.call(user:)

        expect(sqs_client).to have_received(:send_message).with(
          queue_url: "https://sqs.example.com/queue",
          message_body: "alice/avatar/"
        )
      end

      it "sends only the avatar SQS message" do
        operation.call(user:)

        expect(sqs_client).to have_received(:send_message).once
      end
    end

    context "when the cleanup messages are queued" do
      let(:calls) { [] }

      before do
        allow(map_repo).to receive(:find_all_by_user_id).with(1).and_return([map_abc])
        allow(sqs_client).to receive(:send_message) {|**args| calls << [:queued, args[:message_body]] }
        allow(user_repo).to receive(:destroy) {|id| calls << [:destroyed, id] }
      end

      it "queues every prefix before it destroys the user" do
        operation.call(user:)

        expect(calls).to eq([[:queued, "alice/maps/map-abc/"], [:queued, "alice/avatar/"], [:destroyed, 1]])
      end
    end

    context "when SQS send fails" do
      before do
        allow(map_repo).to receive(:find_all_by_user_id).with(1).and_return([map_abc])
        allow(user_repo).to receive(:destroy)
        allow(sqs_client).to receive(:send_message)
          .and_raise(Aws::SQS::Errors::ServiceError.new(nil, "error"))
      end

      it "returns Failure(:bad_gateway)" do
        result = operation.call(user:)

        expect(result).to be_failure
        expect(result.failure).to eq(:bad_gateway)
      end

      it "keeps the user record so that deleting again retries" do
        operation.call(user:)

        expect(user_repo).not_to have_received(:destroy)
      end
    end

    context "when SQS fails after some prefixes were queued" do
      before do
        allow(map_repo).to receive(:find_all_by_user_id).with(1).and_return([map_abc, map_xyz])
        allow(user_repo).to receive(:destroy)
        allow(sqs_client).to receive(:send_message)
          .and_invoke(
            ->(**) {},
            ->(**) { raise Aws::SQS::Errors::ServiceError.new(nil, "error") }
          )
      end

      it "keeps the user record" do
        result = operation.call(user:)

        expect(result.failure).to eq(:bad_gateway)
        expect(user_repo).not_to have_received(:destroy)
      end
    end
  end
end
