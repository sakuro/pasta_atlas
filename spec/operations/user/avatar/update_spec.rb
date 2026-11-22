# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::User::Avatar::Update do
  let(:user_profile_repo) { instance_double(PastaAtlas::Repos::UserProfileRepo) }
  let(:schedule_avatar_cleanup) { instance_double(PastaAtlas::Operations::User::Avatar::ScheduleCleanup) }
  let(:operation) { PastaAtlas::Operations::User::Avatar::Update.new(user_profile_repo:, schedule_avatar_cleanup:) }

  let(:user) { double("User", id: 1, name: "alice") }
  let(:profile_with_avatar) { double("UserProfile", avatar_s3_key: "alice/avatar/old.jpg") }
  let(:profile_without_avatar) { double("UserProfile", avatar_s3_key: nil) }

  describe "#call" do
    context "when s3_key does not match the user's prefix" do
      before do
        allow(user_profile_repo).to receive(:find_by_user_id!).with(1).and_return(profile_without_avatar)
      end

      it "returns Failure(:unprocessable_entity)" do
        result = operation.call(user:, s3_key: "bob/avatar/other.jpg")

        expect(result).to be_failure
        expect(result.failure).to eq(:unprocessable_entity)
      end
    end

    context "when user has no existing avatar" do
      before do
        allow(user_profile_repo).to receive(:find_by_user_id!).with(1).and_return(profile_without_avatar)
        allow(user_profile_repo).to receive(:update_avatar)
        allow(schedule_avatar_cleanup).to receive(:call)
      end

      it "updates the avatar" do
        operation.call(user:, s3_key: "alice/avatar/new.jpg")

        expect(user_profile_repo).to have_received(:update_avatar).with(1, avatar_s3_key: "alice/avatar/new.jpg")
      end

      it "does not schedule a cleanup" do
        operation.call(user:, s3_key: "alice/avatar/new.jpg")

        expect(schedule_avatar_cleanup).not_to have_received(:call)
      end

      it "returns success with the user" do
        result = operation.call(user:, s3_key: "alice/avatar/new.jpg")

        expect(result).to be_success
        expect(result.value!).to eq(user)
      end
    end

    context "when user has an existing avatar" do
      before do
        allow(user_profile_repo).to receive(:find_by_user_id!).with(1).and_return(profile_with_avatar)
        allow(user_profile_repo).to receive(:update_avatar)
        allow(schedule_avatar_cleanup).to receive(:call).and_return(Success())
      end

      it "schedules a cleanup of the old key" do
        operation.call(user:, s3_key: "alice/avatar/new.jpg")

        expect(schedule_avatar_cleanup).to have_received(:call).with(s3_key: "alice/avatar/old.jpg")
      end

      it "does not schedule a cleanup when the key is already the current avatar" do
        operation.call(user:, s3_key: "alice/avatar/old.jpg")

        expect(schedule_avatar_cleanup).not_to have_received(:call)
      end

      context "when the cleanup cannot be scheduled" do
        before { allow(schedule_avatar_cleanup).to receive(:call).and_return(Failure(:enqueue_failed)) }

        it "still returns success" do
          result = operation.call(user:, s3_key: "alice/avatar/new.jpg")

          expect(result).to be_success
        end

        it "still updates the avatar" do
          operation.call(user:, s3_key: "alice/avatar/new.jpg")

          expect(user_profile_repo).to have_received(:update_avatar).with(1, avatar_s3_key: "alice/avatar/new.jpg")
        end
      end
    end
  end
end
