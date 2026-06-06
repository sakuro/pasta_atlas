# frozen_string_literal: true

require "aws-sdk-s3"

RSpec.describe PastaAtlas::Operations::CleanupOrphanedS3Objects do
  let(:map_repo) { instance_double(PastaAtlas::Repos::MapRepo) }
  let(:user_repo) { instance_double(PastaAtlas::Repos::UserRepo) }
  let(:settings) { double("Settings", s3_bucket: "test-bucket") }
  let(:s3_client) { instance_double(Aws::S3::Client) }
  let(:operation) { PastaAtlas::Operations::CleanupOrphanedS3Objects.new(map_repo:, user_repo:, settings:, s3_client:) }

  let(:user) { double("User", id: 1, name: "alice") }

  def stub_list_prefixes(prefix, child_prefixes)
    page = double("Page", common_prefixes: child_prefixes.map {|p| double(prefix: p) })
    result = double("ListResult")
    allow(result).to receive(:each_page).and_yield(page)
    allow(s3_client).to receive(:list_objects_v2)
      .with(bucket: "test-bucket", prefix:, delimiter: "/")
      .and_return(result)
  end

  def stub_list_objects(prefix, keys)
    page = double("Page", contents: keys.map {|k| double(key: k) })
    result = double("ListResult")
    allow(result).to receive(:each_page).and_yield(page)
    allow(s3_client).to receive(:list_objects_v2)
      .with(bucket: "test-bucket", prefix:)
      .and_return(result)
  end

  describe "#call" do
    context "when there are no user prefixes" do
      before { stub_list_prefixes("", []) }

      it "returns success with zero deleted" do
        result = operation.call

        expect(result).to be_success
        expect(result.value!).to eq({deleted_count: 0})
      end
    end

    context "when a user prefix exists but the user is not in the DB" do
      before do
        stub_list_prefixes("", ["alice/"])
        allow(user_repo).to receive(:find_by_name).with("alice").and_return(nil)
      end

      it "skips it and returns zero deleted" do
        result = operation.call

        expect(result).to be_success
        expect(result.value!).to eq({deleted_count: 0})
      end
    end

    context "when a map prefix exists in S3 but not in the DB" do
      before do
        stub_list_prefixes("", ["alice/"])
        stub_list_prefixes("alice/maps/", ["alice/maps/map-abc/"])
        stub_list_objects("alice/maps/map-abc/", ["alice/maps/map-abc/tile.png"])
        allow(user_repo).to receive(:find_by_name).with("alice").and_return(user)
        allow(map_repo).to receive(:find_by_user_and_mapshot_id)
          .with(user_id: 1, mapshot_map_id: "map-abc")
          .and_return(nil)
        allow(s3_client).to receive(:delete_objects)
      end

      it "deletes S3 objects under the orphaned prefix" do
        operation.call

        expect(s3_client).to have_received(:delete_objects).with(
          bucket: "test-bucket",
          delete: {objects: [{key: "alice/maps/map-abc/tile.png"}], quiet: true}
        )
      end

      it "returns success with deleted count" do
        result = operation.call

        expect(result).to be_success
        expect(result.value!).to eq({deleted_count: 1})
      end
    end

    context "when a map prefix exists in both S3 and the DB" do
      before do
        stub_list_prefixes("", ["alice/"])
        stub_list_prefixes("alice/maps/", ["alice/maps/map-abc/"])
        allow(user_repo).to receive(:find_by_name).with("alice").and_return(user)
        allow(map_repo).to receive(:find_by_user_and_mapshot_id)
          .with(user_id: 1, mapshot_map_id: "map-abc")
          .and_return(double("Map"))
        allow(s3_client).to receive(:delete_objects)
      end

      it "does not delete anything" do
        operation.call

        expect(s3_client).not_to have_received(:delete_objects)
      end

      it "returns success with zero deleted" do
        result = operation.call

        expect(result).to be_success
        expect(result.value!).to eq({deleted_count: 0})
      end
    end

    context "when S3 raises an error" do
      before do
        allow(s3_client).to receive(:list_objects_v2)
          .and_raise(Aws::S3::Errors::ServiceError.new(nil, "error"))
      end

      it "returns failure with :s3_error" do
        result = operation.call

        expect(result).to be_failure
        expect(result.failure).to eq(:s3_error)
      end
    end
  end
end
