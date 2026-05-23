# frozen_string_literal: true

require "aws-sdk-sqs"

RSpec.describe PastaAtlas::Operations::Maps::RequestDeletion do
  let(:map_repo) { instance_double(PastaAtlas::Repos::MapRepo) }
  let(:user_repo) { instance_double(PastaAtlas::Repos::UserRepo) }
  let(:settings) { double("Settings", sqs_s3_cleanup_queue_url: "https://sqs.example.com/queue") }
  let(:sqs_client) { instance_double(Aws::SQS::Client) }
  let(:operation) { PastaAtlas::Operations::Maps::RequestDeletion.new(map_repo:, user_repo:, settings:, sqs_client:) }

  let(:user) { double("User", id: 1, name: "alice", guest?: false) }
  let(:map) { double("Map", id: 10, ulid: "01MAP1", user_id: 1, mapshot_map_id: "map-abc", owned_by?: true) }

  describe "#call" do
    context "when user is not logged in" do
      it "returns failure with :unauthorized" do
        result = operation.call(ulid: "01MAP1", current_user_id: nil)

        expect(result).to be_failure
        expect(result.failure).to eq(:unauthorized)
      end
    end

    context "when user is a guest" do
      let(:guest) { double("User", id: 2, guest?: true) }

      before { allow(user_repo).to receive(:find_by_id).with(2).and_return(guest) }

      it "returns failure with :forbidden" do
        result = operation.call(ulid: "01MAP1", current_user_id: 2)

        expect(result).to be_failure
        expect(result.failure).to eq(:forbidden)
      end
    end

    context "when map is not found" do
      before do
        allow(user_repo).to receive(:find_by_id).with(1).and_return(user)
        allow(map_repo).to receive(:find_by_ulid).with("NOTFOUND").and_return(nil)
      end

      it "returns failure with :not_found" do
        result = operation.call(ulid: "NOTFOUND", current_user_id: 1)

        expect(result).to be_failure
        expect(result.failure).to eq(:not_found)
      end
    end

    context "when user does not own the map" do
      let(:other_map) { double("Map", id: 10, ulid: "01MAP1", user_id: 99, owned_by?: false) }

      before do
        allow(user_repo).to receive(:find_by_id).with(1).and_return(user)
        allow(map_repo).to receive(:find_by_ulid).with("01MAP1").and_return(other_map)
      end

      it "returns failure with :forbidden" do
        result = operation.call(ulid: "01MAP1", current_user_id: 1)

        expect(result).to be_failure
        expect(result.failure).to eq(:forbidden)
      end
    end

    context "when user owns the map" do
      before do
        allow(user_repo).to receive(:find_by_id).with(1).and_return(user)
        allow(map_repo).to receive(:find_by_ulid).with("01MAP1").and_return(map)
        allow(map).to receive(:owned_by?).with(user).and_return(true)
        allow(map_repo).to receive(:delete_by_id).with(10)
        allow(sqs_client).to receive(:send_message)
      end

      it "deletes the map DB record" do
        operation.call(ulid: "01MAP1", current_user_id: 1)

        expect(map_repo).to have_received(:delete_by_id).with(10)
      end

      it "sends an SQS message with the S3 prefix" do
        operation.call(ulid: "01MAP1", current_user_id: 1)

        expect(sqs_client).to have_received(:send_message).with(
          queue_url: "https://sqs.example.com/queue",
          message_body: "alice/map-abc/"
        )
      end

      it "returns success with the map" do
        result = operation.call(ulid: "01MAP1", current_user_id: 1)

        expect(result).to be_success
        expect(result.value!).to eq(map)
      end

      context "when SQS send fails" do
        before do
          allow(sqs_client).to receive(:send_message)
            .and_raise(Aws::SQS::Errors::ServiceError.new(nil, "error"))
        end

        it "still returns success" do
          result = operation.call(ulid: "01MAP1", current_user_id: 1)

          expect(result).to be_success
        end

        it "still deletes the DB record" do
          operation.call(ulid: "01MAP1", current_user_id: 1)

          expect(map_repo).to have_received(:delete_by_id).with(10)
        end
      end
    end
  end
end
