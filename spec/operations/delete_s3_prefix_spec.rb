# frozen_string_literal: true

require "aws-sdk-s3"

RSpec.describe PastaAtlas::Operations::DeleteS3Prefix do
  let(:settings) { double("Settings", s3_bucket: "test-bucket") }
  let(:s3_client) { instance_double(Aws::S3::Client) }
  let(:operation) { PastaAtlas::Operations::DeleteS3Prefix.new(settings:, s3_client:) }

  describe "#call" do
    context "when S3 deletion fails" do
      before do
        allow(s3_client).to receive(:list_objects_v2)
          .and_raise(Aws::S3::Errors::ServiceError.new(nil, "error"))
      end

      it "returns failure with :s3_error" do
        result = operation.call(s3_prefix: "alice/map-abc/")

        expect(result).to be_failure
        expect(result.failure).to eq(:s3_error)
      end
    end

    context "when deletion succeeds" do
      let(:s3_object) { double("S3Object", key: "alice/map-abc/tile.png") }
      let(:page) { double("Page", contents: [s3_object]) }
      let(:list_result) { double("ListResult") }

      before do
        allow(list_result).to receive(:each_page).and_yield(page)
        allow(s3_client).to receive(:list_objects_v2)
          .with(bucket: "test-bucket", prefix: "alice/map-abc/")
          .and_return(list_result)
        allow(s3_client).to receive(:delete_objects)
      end

      it "deletes S3 objects under the prefix" do
        operation.call(s3_prefix: "alice/map-abc/")

        expect(s3_client).to have_received(:delete_objects).with(
          bucket: "test-bucket",
          delete: {objects: [{key: "alice/map-abc/tile.png"}], quiet: true}
        )
      end

      it "returns success with the prefix" do
        result = operation.call(s3_prefix: "alice/map-abc/")

        expect(result).to be_success
        expect(result.value!).to eq("alice/map-abc/")
      end
    end

    context "when there are no S3 objects" do
      let(:page) { double("Page", contents: []) }
      let(:list_result) { double("ListResult") }

      before do
        allow(list_result).to receive(:each_page).and_yield(page)
        allow(s3_client).to receive(:list_objects_v2)
          .with(bucket: "test-bucket", prefix: "alice/map-abc/")
          .and_return(list_result)
        allow(s3_client).to receive(:delete_objects)
      end

      it "skips delete_objects and returns success" do
        result = operation.call(s3_prefix: "alice/map-abc/")

        expect(s3_client).not_to have_received(:delete_objects)
        expect(result).to be_success
      end
    end
  end
end
