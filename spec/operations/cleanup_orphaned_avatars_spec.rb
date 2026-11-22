# frozen_string_literal: true

require "aws-sdk-s3"

RSpec.describe PastaAtlas::Operations::CleanupOrphanedAvatars do
  let(:avatar_upload_repo) { instance_double(PastaAtlas::Repos::AvatarUploadRepo) }
  let(:user_repo) { instance_double(PastaAtlas::Repos::UserRepo) }
  let(:user_profile_repo) { instance_double(PastaAtlas::Repos::UserProfileRepo) }
  let(:settings) { double("Settings", s3_bucket: "test-bucket") }
  let(:s3_client) { instance_double(Aws::S3::Client) }
  let(:operation) do
    PastaAtlas::Operations::CleanupOrphanedAvatars.new(avatar_upload_repo:, user_repo:, user_profile_repo:, settings:, s3_client:)
  end

  let(:now) { Time.utc(2026, 11, 22, 12, 0, 0) }
  let(:old) { now - (2 * 24 * 60 * 60) }
  let(:recent) { now - (60 * 60) }
  let(:user) { double("User", id: 1, name: "alice") }

  def stub_user_prefixes(prefixes)
    page = double("Page", common_prefixes: prefixes.map {|p| double(prefix: p) })
    result = double("ListResult")
    allow(result).to receive(:each_page).and_yield(page)
    allow(s3_client).to receive(:list_objects_v2)
      .with(bucket: "test-bucket", prefix: "", delimiter: "/")
      .and_return(result)
  end

  def stub_avatar_objects(prefix, objects)
    page = double("Page", contents: objects.map {|key, last_modified| double(key:, last_modified:) })
    result = double("ListResult")
    allow(result).to receive(:each_page).and_yield(page)
    allow(s3_client).to receive(:list_objects_v2)
      .with(bucket: "test-bucket", prefix:)
      .and_return(result)
  end

  before do
    allow(s3_client).to receive(:delete_objects)
    allow(avatar_upload_repo).to receive(:delete_expired_before).and_return(0)
  end

  describe "#call" do
    context "when there are no user prefixes" do
      before { stub_user_prefixes([]) }

      it "returns success with zero deleted" do
        expect(operation.call(now:).value!).to eq({deleted_count: 0, deleted_uploads: 0})
      end
    end

    context "when issued avatar keys are well past their expiry" do
      before do
        stub_user_prefixes([])
        allow(avatar_upload_repo).to receive(:delete_expired_before).and_return(3)
      end

      it "deletes their records and reports how many" do
        result = operation.call(now:)

        expect(result.value!).to eq({deleted_count: 0, deleted_uploads: 3})
        expect(avatar_upload_repo).to have_received(:delete_expired_before).with(now - (24 * 60 * 60))
      end
    end

    context "when a user has avatar objects" do
      before do
        stub_user_prefixes(["alice/"])
        allow(user_repo).to receive(:find_by_name).with("alice").and_return(user)
        allow(user_profile_repo).to receive(:find_by_user_id!).with(1)
          .and_return(double("UserProfile", avatar_s3_key: "alice/avatar/current.jpg"))
        stub_avatar_objects("alice/avatar/", {
          "alice/avatar/current.jpg" => old,
          "alice/avatar/stale.jpg" => old,
          "alice/avatar/just-uploaded.jpg" => recent
        })
      end

      it "deletes only the old objects the profile does not refer to" do
        operation.call(now:)

        expect(s3_client).to have_received(:delete_objects).once.with(
          bucket: "test-bucket",
          delete: {objects: [{key: "alice/avatar/stale.jpg"}], quiet: true}
        )
      end

      it "returns the number of deleted objects" do
        expect(operation.call(now:).value!).to eq({deleted_count: 1, deleted_uploads: 0})
      end
    end

    context "when the profile has no avatar" do
      before do
        stub_user_prefixes(["alice/"])
        allow(user_repo).to receive(:find_by_name).with("alice").and_return(user)
        allow(user_profile_repo).to receive(:find_by_user_id!).with(1)
          .and_return(double("UserProfile", avatar_s3_key: nil))
        stub_avatar_objects("alice/avatar/", {"alice/avatar/stale.jpg" => old})
      end

      it "deletes every old avatar object" do
        operation.call(now:)

        expect(s3_client).to have_received(:delete_objects).with(
          bucket: "test-bucket",
          delete: {objects: [{key: "alice/avatar/stale.jpg"}], quiet: true}
        )
      end
    end

    context "when the user is not in the database" do
      before do
        stub_user_prefixes(["ghost/"])
        allow(user_repo).to receive(:find_by_name).with("ghost").and_return(nil)
      end

      it "leaves the prefix alone" do
        result = operation.call(now:)

        expect(result.value!).to eq({deleted_count: 0, deleted_uploads: 0})
        expect(s3_client).not_to have_received(:delete_objects)
      end
    end

    context "when there are more orphans than one DeleteObjects request accepts" do
      before do
        stub_user_prefixes(["alice/"])
        allow(user_repo).to receive(:find_by_name).with("alice").and_return(user)
        allow(user_profile_repo).to receive(:find_by_user_id!).with(1)
          .and_return(double("UserProfile", avatar_s3_key: nil))
        stub_avatar_objects("alice/avatar/", (1..1001).to_h {|i| ["alice/avatar/#{i}.jpg", old] })
      end

      it "deletes them in batches of 1000" do
        result = operation.call(now:)

        expect(result.value!).to eq({deleted_count: 1001, deleted_uploads: 0})
        expect(s3_client).to have_received(:delete_objects).twice
      end
    end

    context "when S3 raises a service error" do
      before do
        allow(s3_client).to receive(:list_objects_v2).and_raise(Aws::S3::Errors::ServiceError.new(nil, "error"))
      end

      it "returns Failure(:s3_error)" do
        result = operation.call(now:)

        expect(result).to be_failure
        expect(result.failure).to eq(:s3_error)
      end
    end
  end
end
