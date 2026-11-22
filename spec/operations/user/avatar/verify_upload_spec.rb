# frozen_string_literal: true

require "aws-sdk-s3"

RSpec.describe PastaAtlas::Operations::User::Avatar::VerifyUpload do
  let(:avatar_upload_repo) { instance_double(PastaAtlas::Repos::AvatarUploadRepo) }
  let(:settings) { double("Settings", s3_bucket: "test-bucket") }
  let(:s3_client) { instance_double(Aws::S3::Client) }
  let(:operation) { PastaAtlas::Operations::User::Avatar::VerifyUpload.new(avatar_upload_repo:, settings:, s3_client:) }

  let(:now) { Time.utc(2026, 11, 22, 12, 0, 0) }
  let(:user) { double("User", id: 1, name: "alice") }
  let(:s3_key) { "alice/avatar/01ABC.png" }
  let(:upload) { double("AvatarUpload", id: 7, s3_key:, content_type: "image/png") }
  let(:png_header) { "\x89PNG\r\n\x1A\n\x00\x00\x00\rIHDR".b }
  let(:head) { double("HeadObjectOutput", content_length: 2048, content_type: "image/png") }

  def call_operation = operation.call(user:, s3_key:, now:)

  before do
    allow(avatar_upload_repo).to receive(:find_pending).with(user_id: 1, s3_key:, now:).and_return(upload)
    allow(avatar_upload_repo).to receive(:consume).with(id: 7, now:).and_return(1)
    allow(s3_client).to receive(:head_object).with(bucket: "test-bucket", key: s3_key).and_return(head)
    allow(s3_client).to receive(:get_object)
      .with(bucket: "test-bucket", key: s3_key, range: "bytes=0-11")
      .and_return(double("GetObjectOutput", body: StringIO.new(png_header)))
  end

  describe "#call" do
    it "returns the key and consumes the issued upload" do
      result = call_operation

      expect(result).to be_success
      expect(result.value!).to eq(s3_key)
      expect(avatar_upload_repo).to have_received(:consume).with(id: 7, now:)
    end

    context "when the key was not issued to the user, or is expired or applied" do
      before { allow(avatar_upload_repo).to receive(:find_pending).and_return(nil) }

      it "returns Failure(:unprocessable_entity) without touching S3" do
        result = call_operation

        expect(result.failure).to eq(:unprocessable_entity)
        expect(s3_client).not_to have_received(:head_object)
      end
    end

    context "when the object does not exist" do
      before { allow(s3_client).to receive(:head_object).and_raise(Aws::S3::Errors::NotFound.new(nil, "not found")) }

      it "returns Failure(:unprocessable_entity)" do
        expect(call_operation.failure).to eq(:unprocessable_entity)
      end
    end

    context "when the object is larger than an avatar may be" do
      let(:head) { double("HeadObjectOutput", content_length: (5 * 1024 * 1024) + 1, content_type: "image/png") }

      it "returns Failure(:unprocessable_entity) and does not consume the upload" do
        result = call_operation

        expect(result.failure).to eq(:unprocessable_entity)
        expect(avatar_upload_repo).not_to have_received(:consume)
      end
    end

    context "when the object is empty" do
      let(:head) { double("HeadObjectOutput", content_length: 0, content_type: "image/png") }

      it "returns Failure(:unprocessable_entity)" do
        expect(call_operation.failure).to eq(:unprocessable_entity)
      end
    end

    context "when the stored content type differs from the issued one" do
      let(:head) { double("HeadObjectOutput", content_length: 2048, content_type: "text/html") }

      it "returns Failure(:unprocessable_entity)" do
        expect(call_operation.failure).to eq(:unprocessable_entity)
      end
    end

    context "when the content is not an image of the issued type" do
      let(:png_header) { "<!doctype html>".b }

      it "returns Failure(:unprocessable_entity) and does not consume the upload" do
        result = call_operation

        expect(result.failure).to eq(:unprocessable_entity)
        expect(avatar_upload_repo).not_to have_received(:consume)
      end
    end

    context "when another request consumed the upload first" do
      before { allow(avatar_upload_repo).to receive(:consume).and_return(0) }

      it "returns Failure(:unprocessable_entity)" do
        expect(call_operation.failure).to eq(:unprocessable_entity)
      end
    end

    context "when S3 raises a service error" do
      before { allow(s3_client).to receive(:head_object).and_raise(Aws::S3::Errors::ServiceError.new(nil, "error")) }

      it "returns Failure(:bad_gateway)" do
        expect(call_operation.failure).to eq(:bad_gateway)
      end
    end
  end
end
