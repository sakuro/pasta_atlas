# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::User::Profile::Update do
  let(:user_profile_repo) { instance_double(PastaAtlas::Repos::UserProfileRepo) }
  let(:schedule_avatar_cleanup) { instance_double(PastaAtlas::Operations::User::Avatar::ScheduleCleanup) }
  let(:operation) { PastaAtlas::Operations::User::Profile::Update.new(user_profile_repo:, schedule_avatar_cleanup:) }

  let(:user) { double("User", id: 1, name: "wube") }

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

    context "when a valid avatar_s3_key is provided" do
      let(:current_avatar_s3_key) { nil }

      before do
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

      context "when the user has a different current avatar" do
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

      context "when the key is already the current avatar" do
        let(:current_avatar_s3_key) { "wube/avatar/abc.jpg" }

        it "does not schedule a cleanup" do
          operation.call(user:, display_name: "Wube", avatar_s3_key: "wube/avatar/abc.jpg")

          expect(schedule_avatar_cleanup).not_to have_received(:call)
        end
      end
    end

    context "when avatar_s3_key is blank or outside the user's prefix" do
      before do
        allow(user_profile_repo).to receive(:update_profile)
        allow(user_profile_repo).to receive(:update_avatar)
        allow(schedule_avatar_cleanup).to receive(:call)
      end

      it "leaves the avatar alone" do
        operation.call(user:, display_name: "Wube", avatar_s3_key: "")
        operation.call(user:, display_name: "Wube", avatar_s3_key: "bob/avatar/abc.jpg")

        expect(user_profile_repo).not_to have_received(:update_avatar)
        expect(schedule_avatar_cleanup).not_to have_received(:call)
      end
    end
  end
end
