# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::User::Avatar::Destroy do
  let(:user_profile_repo) { instance_double(PastaAtlas::Repos::UserProfileRepo) }
  let(:schedule_avatar_cleanup) { instance_double(PastaAtlas::Operations::User::Avatar::ScheduleCleanup) }
  let(:operation) { PastaAtlas::Operations::User::Avatar::Destroy.new(user_profile_repo:, schedule_avatar_cleanup:) }

  let(:user) { double("User", id: 1, name: "alice") }
  let(:profile_with_avatar) { double("UserProfile", avatar_s3_key: "alice/avatar/photo.jpg") }
  let(:profile_without_avatar) { double("UserProfile", avatar_s3_key: nil) }

  describe "#call" do
    context "when user has no avatar" do
      before do
        allow(user_profile_repo).to receive(:find_by_user_id!).with(1).and_return(profile_without_avatar)
        allow(user_profile_repo).to receive(:clear_avatar)
        allow(schedule_avatar_cleanup).to receive(:call)
      end

      it "clears the avatar" do
        operation.call(user:)

        expect(user_profile_repo).to have_received(:clear_avatar).with(1)
      end

      it "does not schedule a cleanup" do
        operation.call(user:)

        expect(schedule_avatar_cleanup).not_to have_received(:call)
      end

      it "returns success with the user" do
        result = operation.call(user:)

        expect(result).to be_success
        expect(result.value!).to eq(user)
      end
    end

    context "when user has an avatar" do
      before do
        allow(user_profile_repo).to receive(:find_by_user_id!).with(1).and_return(profile_with_avatar)
        allow(user_profile_repo).to receive(:clear_avatar)
        allow(schedule_avatar_cleanup).to receive(:call).and_return(Success())
      end

      it "clears the avatar" do
        operation.call(user:)

        expect(user_profile_repo).to have_received(:clear_avatar).with(1)
      end

      it "schedules a cleanup of the old key" do
        operation.call(user:)

        expect(schedule_avatar_cleanup).to have_received(:call).with(s3_key: "alice/avatar/photo.jpg")
      end

      it "returns success with the user" do
        result = operation.call(user:)

        expect(result).to be_success
        expect(result.value!).to eq(user)
      end

      it "still succeeds when the cleanup cannot be scheduled" do
        allow(schedule_avatar_cleanup).to receive(:call).and_return(Failure(:enqueue_failed))

        result = operation.call(user:)

        expect(result).to be_success
        expect(user_profile_repo).to have_received(:clear_avatar).with(1)
      end
    end
  end
end
