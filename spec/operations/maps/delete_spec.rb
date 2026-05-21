# frozen_string_literal: true

require "aws-sdk-s3"

RSpec.describe PastaAtlas::Operations::Maps::Delete do
  let(:map_repo) { instance_double(PastaAtlas::Repos::MapRepo) }
  let(:user_repo) { instance_double(PastaAtlas::Repos::UserRepo) }
  let(:settings) { double("Settings", s3_bucket: "test-bucket") }
  let(:s3_client) { instance_double(Aws::S3::Client) }
  let(:operation) { PastaAtlas::Operations::Maps::Delete.new(map_repo:, user_repo:, settings:, s3_client:) }

  let(:user) { double("User", id: 1, name: "alice") }
  let(:map) { double("Map", id: 10, ulid: "01MAP1", user_id: 1, mapshot_map_id: "map-abc") }

  describe "#call" do
    context "when map is not found" do
      before { allow(map_repo).to receive(:find_by_ulid).with("NOTFOUND").and_return(nil) }

      it "returns failure with :not_found" do
        result = operation.call(ulid: "NOTFOUND")

        expect(result).to be_failure
        expect(result.failure).to eq(:not_found)
      end
    end

    context "when S3 deletion fails" do
      before do
        allow(map_repo).to receive(:find_by_ulid).with("01MAP1").and_return(map)
        allow(map_repo).to receive(:delete_by_id)
        allow(user_repo).to receive(:find_by_id).with(1).and_return(user)
        allow(s3_client).to receive(:list_objects_v2)
          .and_raise(Aws::S3::Errors::ServiceError.new(nil, "error"))
      end

      it "returns failure with :s3_error" do
        result = operation.call(ulid: "01MAP1")

        expect(result).to be_failure
        expect(result.failure).to eq(:s3_error)
      end

      it "does not delete the DB record" do
        operation.call(ulid: "01MAP1")

        expect(map_repo).not_to have_received(:delete_by_id)
      end
    end

    context "when deletion succeeds" do
      let(:s3_object) { double("S3Object", key: "alice/map-abc/tile.png") }
      let(:page) { double("Page", contents: [s3_object]) }
      let(:list_result) { double("ListResult") }

      before do
        allow(map_repo).to receive(:find_by_ulid).with("01MAP1").and_return(map)
        allow(user_repo).to receive(:find_by_id).with(1).and_return(user)
        allow(list_result).to receive(:each_page).and_yield(page)
        allow(s3_client).to receive(:list_objects_v2)
          .with(bucket: "test-bucket", prefix: "alice/map-abc/")
          .and_return(list_result)
        allow(s3_client).to receive(:delete_objects)
        allow(map_repo).to receive(:delete_by_id).with(10)
      end

      it "deletes S3 objects under the map prefix" do
        operation.call(ulid: "01MAP1")

        expect(s3_client).to have_received(:delete_objects).with(
          bucket: "test-bucket",
          delete: {objects: [{key: "alice/map-abc/tile.png"}], quiet: true}
        )
      end

      it "deletes the map DB record" do
        operation.call(ulid: "01MAP1")

        expect(map_repo).to have_received(:delete_by_id).with(10)
      end

      it "returns success with the map" do
        result = operation.call(ulid: "01MAP1")

        expect(result).to be_success
        expect(result.value!).to eq(map)
      end
    end

    context "when there are no S3 objects" do
      let(:page) { double("Page", contents: []) }
      let(:list_result) { double("ListResult") }

      before do
        allow(map_repo).to receive(:find_by_ulid).with("01MAP1").and_return(map)
        allow(user_repo).to receive(:find_by_id).with(1).and_return(user)
        allow(list_result).to receive(:each_page).and_yield(page)
        allow(s3_client).to receive(:list_objects_v2)
          .with(bucket: "test-bucket", prefix: "alice/map-abc/")
          .and_return(list_result)
        allow(s3_client).to receive(:delete_objects)
        allow(map_repo).to receive(:delete_by_id).with(10)
      end

      it "skips delete_objects and still deletes the DB record" do
        operation.call(ulid: "01MAP1")

        expect(s3_client).not_to have_received(:delete_objects)
        expect(map_repo).to have_received(:delete_by_id).with(10)
      end
    end
  end
end
