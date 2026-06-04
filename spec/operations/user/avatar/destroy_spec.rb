# frozen_string_literal: true

require "aws-sdk-sqs"

RSpec.describe PastaAtlas::Operations::User::Avatar::Destroy do
  let(:user_profile_repo) { instance_double(PastaAtlas::Repos::UserProfileRepo) }
  let(:settings) { double("Settings", sqs_s3_cleanup_queue_url: "https://sqs.example.com/queue") }
  let(:sqs_client) { instance_double(Aws::SQS::Client) }
  let(:operation) { PastaAtlas::Operations::User::Avatar::Destroy.new(user_profile_repo:, settings:, sqs_client:) }

  let(:user) { double("User", id: 1, name: "alice") }
  let(:profile_with_avatar) { double("UserProfile", avatar_s3_key: "alice/avatar/photo.jpg") }
  let(:profile_without_avatar) { double("UserProfile", avatar_s3_key: nil) }

  describe "#call" do
    context "when user has no avatar" do
      before do
        allow(user_profile_repo).to receive(:find_by_user_id).with(1).and_return(profile_without_avatar)
        allow(user_profile_repo).to receive(:clear_avatar)
        allow(sqs_client).to receive(:send_message)
      end

      it "clears the avatar" do
        operation.call(user:)

        expect(user_profile_repo).to have_received(:clear_avatar).with(1)
      end

      it "does not send an SQS message" do
        operation.call(user:)

        expect(sqs_client).not_to have_received(:send_message)
      end

      it "returns success with the user" do
        result = operation.call(user:)

        expect(result).to be_success
        expect(result.value!).to eq(user)
      end
    end

    context "when user has an avatar" do
      before do
        allow(user_profile_repo).to receive(:find_by_user_id).with(1).and_return(profile_with_avatar)
        allow(user_profile_repo).to receive(:clear_avatar)
        allow(sqs_client).to receive(:send_message)
      end

      it "clears the avatar" do
        operation.call(user:)

        expect(user_profile_repo).to have_received(:clear_avatar).with(1)
      end

      it "sends an SQS message with the old key for cleanup" do
        operation.call(user:)

        expect(sqs_client).to have_received(:send_message).with(
          queue_url: "https://sqs.example.com/queue",
          message_body: "alice/avatar/photo.jpg"
        )
      end

      it "returns success with the user" do
        result = operation.call(user:)

        expect(result).to be_success
        expect(result.value!).to eq(user)
      end

      context "when SQS send fails" do
        before do
          allow(sqs_client).to receive(:send_message)
            .and_raise(Aws::SQS::Errors::ServiceError.new(nil, "error"))
        end

        it "still returns success" do
          result = operation.call(user:)

          expect(result).to be_success
        end

        it "still clears the avatar" do
          operation.call(user:)

          expect(user_profile_repo).to have_received(:clear_avatar).with(1)
        end
      end
    end
  end
end
