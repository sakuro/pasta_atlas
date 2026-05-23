# frozen_string_literal: true

require "aws-sdk-sqs"

RSpec.describe PastaAtlas::Operations::User::Avatar::Update do
  let(:verify_ownership) { instance_double(PastaAtlas::Operations::User::VerifyOwnership) }
  let(:user_profile_repo) { instance_double(PastaAtlas::Repos::UserProfileRepo) }
  let(:settings) { double("Settings", sqs_s3_cleanup_queue_url: "https://sqs.example.com/queue") }
  let(:sqs_client) { instance_double(Aws::SQS::Client) }
  let(:operation) { PastaAtlas::Operations::User::Avatar::Update.new(verify_ownership:, user_profile_repo:, settings:, sqs_client:) }

  let(:user) { double("User", id: 1, name: "alice") }
  let(:profile_with_avatar) { double("UserProfile", avatar_s3_key: "avatars/1/old.jpg") }
  let(:profile_without_avatar) { double("UserProfile", avatar_s3_key: nil) }

  before do
    allow(verify_ownership).to receive(:call)
      .with(user_id: 1, user_name: "alice").and_return(Success(user))
  end

  describe "#call" do
    context "when verify_ownership fails" do
      before do
        allow(verify_ownership).to receive(:call)
          .with(user_id: nil, user_name: "alice").and_return(Failure(:forbidden))
      end

      it "returns failure" do
        result = operation.call(user_id: nil, user_name: "alice", s3_key: "avatars/1/new.jpg")

        expect(result).to be_failure
      end
    end

    context "when s3_key does not match the user's prefix" do
      before do
        allow(user_profile_repo).to receive(:find_by_user_id).with(1).and_return(profile_without_avatar)
      end

      it "returns Failure(:unprocessable_entity)" do
        result = operation.call(user_id: 1, user_name: "alice", s3_key: "avatars/999/other.jpg")

        expect(result).to be_failure
        expect(result.failure).to eq(:unprocessable_entity)
      end
    end

    context "when user has no existing avatar" do
      before do
        allow(user_profile_repo).to receive(:find_by_user_id).with(1).and_return(profile_without_avatar)
        allow(user_profile_repo).to receive(:update_avatar)
        allow(sqs_client).to receive(:send_message)
      end

      it "updates the avatar" do
        operation.call(user_id: 1, user_name: "alice", s3_key: "avatars/1/new.jpg")

        expect(user_profile_repo).to have_received(:update_avatar).with(1, avatar_s3_key: "avatars/1/new.jpg")
      end

      it "does not send an SQS message" do
        operation.call(user_id: 1, user_name: "alice", s3_key: "avatars/1/new.jpg")

        expect(sqs_client).not_to have_received(:send_message)
      end

      it "returns success with the user" do
        result = operation.call(user_id: 1, user_name: "alice", s3_key: "avatars/1/new.jpg")

        expect(result).to be_success
        expect(result.value!).to eq(user)
      end
    end

    context "when user has an existing avatar" do
      before do
        allow(user_profile_repo).to receive(:find_by_user_id).with(1).and_return(profile_with_avatar)
        allow(user_profile_repo).to receive(:update_avatar)
        allow(sqs_client).to receive(:send_message)
      end

      it "sends an SQS message with the old key for cleanup" do
        operation.call(user_id: 1, user_name: "alice", s3_key: "avatars/1/new.jpg")

        expect(sqs_client).to have_received(:send_message).with(
          queue_url: "https://sqs.example.com/queue",
          message_body: "avatars/1/old.jpg"
        )
      end

      context "when SQS send fails" do
        before do
          allow(sqs_client).to receive(:send_message)
            .and_raise(Aws::SQS::Errors::ServiceError.new(nil, "error"))
        end

        it "still returns success" do
          result = operation.call(user_id: 1, user_name: "alice", s3_key: "avatars/1/new.jpg")

          expect(result).to be_success
        end

        it "still updates the avatar" do
          operation.call(user_id: 1, user_name: "alice", s3_key: "avatars/1/new.jpg")

          expect(user_profile_repo).to have_received(:update_avatar).with(1, avatar_s3_key: "avatars/1/new.jpg")
        end
      end
    end
  end
end
