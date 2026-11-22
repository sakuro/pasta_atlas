# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::User::Profile::Update do
  let(:user_profile_repo) { instance_double(PastaAtlas::Repos::UserProfileRepo) }
  let(:schedule_avatar_cleanup) { instance_double(PastaAtlas::Operations::User::Avatar::ScheduleCleanup) }
  let(:verify_avatar_upload) { instance_double(PastaAtlas::Operations::User::Avatar::VerifyUpload) }
  let(:operation) do
    PastaAtlas::Operations::User::Profile::Update.new(user_profile_repo:, schedule_avatar_cleanup:, verify_avatar_upload:)
  end

  let(:user) { double("User", id: 1, name: "wube") }

  before { allow(verify_avatar_upload).to receive(:call) }

  describe "#call" do
    context "when display_name is valid" do
      before { allow(user_profile_repo).to receive(:update_profile) }

      it "updates profile and returns the user" do
        result = operation.call(user:, display_name: "Wube", avatar_s3_key: "")

        expect(result).to be_success
        expect(result.value!).to eq(user)
        expect(user_profile_repo).to have_received(:update_profile).with(1, display_name: "Wube")
      end
    end

    context "when display_name is blank" do
      before { allow(user_profile_repo).to receive(:update_profile) }

      it "clears display_name" do
        operation.call(user:, display_name: "", avatar_s3_key: "")

        expect(user_profile_repo).to have_received(:update_profile).with(1, display_name: nil)
      end
    end

    context "when display_name exceeds 30 grapheme clusters" do
      it "returns Failure([:invalid, message])" do
        result = operation.call(user:, display_name: "あ" * 31, avatar_s3_key: "")

        expect(result).to be_failure
        code, message = result.failure
        expect(code).to eq(:invalid)
        expect(message).to eq("error-profile-display-name-too-long")
      end
    end

    context "when display_name contains disallowed characters" do
      it "returns Failure([:invalid, message])" do
        result = operation.call(user:, display_name: "bad\tname", avatar_s3_key: "")

        expect(result).to be_failure
        code, _message = result.failure
        expect(code).to eq(:invalid)
      end
    end

    context "when avatar_s3_key is blank" do
      before do
        allow(user_profile_repo).to receive(:update_profile)
        allow(user_profile_repo).to receive(:update_avatar)
      end

      it "leaves the avatar alone without verifying anything" do
        operation.call(user:, display_name: "Wube", avatar_s3_key: "")

        expect(verify_avatar_upload).not_to have_received(:call)
        expect(user_profile_repo).not_to have_received(:update_avatar)
      end
    end

    context "when avatar_s3_key cannot be verified" do
      before do
        allow(verify_avatar_upload).to receive(:call).and_return(Failure(:unprocessable_entity))
        allow(user_profile_repo).to receive(:update_profile)
        allow(user_profile_repo).to receive(:update_avatar)
      end

      it "returns Failure([:invalid, message]) and changes neither the display name nor the avatar" do
        result = operation.call(user:, display_name: "Wube", avatar_s3_key: "wube/avatar/abc.jpg")

        expect(result).to be_failure
        expect(result.failure).to eq([:invalid, "error-profile-avatar-invalid"])
        expect(user_profile_repo).not_to have_received(:update_profile)
        expect(user_profile_repo).not_to have_received(:update_avatar)
      end
    end

    context "when S3 cannot be reached to verify the avatar" do
      before do
        allow(verify_avatar_upload).to receive(:call).and_return(Failure(:bad_gateway))
        allow(user_profile_repo).to receive(:update_profile)
      end

      it "returns the failure as it is" do
        result = operation.call(user:, display_name: "Wube", avatar_s3_key: "wube/avatar/abc.jpg")

        expect(result.failure).to eq(:bad_gateway)
        expect(user_profile_repo).not_to have_received(:update_profile)
      end
    end

    context "when avatar_s3_key is verified" do
      let(:current_avatar_s3_key) { nil }

      before do
        allow(verify_avatar_upload).to receive(:call).with(user:, s3_key: "wube/avatar/abc.jpg")
          .and_return(Success("wube/avatar/abc.jpg"))
        allow(user_profile_repo).to receive(:update_profile)
        allow(user_profile_repo).to receive(:update_avatar)
        allow(user_profile_repo).to receive(:find_by_user_id!).with(1)
          .and_return(double("UserProfile", avatar_s3_key: current_avatar_s3_key))
        allow(schedule_avatar_cleanup).to receive(:call).and_return(Success())
      end

      it "updates the avatar" do
        operation.call(user:, display_name: "Wube", avatar_s3_key: "wube/avatar/abc.jpg")

        expect(user_profile_repo).to have_received(:update_avatar).with(1, avatar_s3_key: "wube/avatar/abc.jpg")
      end

      context "when the user has no current avatar" do
        it "does not schedule a cleanup" do
          operation.call(user:, display_name: "Wube", avatar_s3_key: "wube/avatar/abc.jpg")

          expect(schedule_avatar_cleanup).not_to have_received(:call)
        end
      end

      context "when the user has a current avatar" do
        let(:current_avatar_s3_key) { "wube/avatar/old.jpg" }

        it "schedules a cleanup of the previous key" do
          operation.call(user:, display_name: "Wube", avatar_s3_key: "wube/avatar/abc.jpg")

          expect(schedule_avatar_cleanup).to have_received(:call).with(s3_key: "wube/avatar/old.jpg")
        end

        it "still succeeds when the cleanup cannot be scheduled" do
          allow(schedule_avatar_cleanup).to receive(:call).and_return(Failure(:enqueue_failed))

          result = operation.call(user:, display_name: "Wube", avatar_s3_key: "wube/avatar/abc.jpg")

          expect(result).to be_success
        end
      end
    end
  end
end
