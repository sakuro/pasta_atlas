# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::Registrations::ImportAvatar do
  let(:operation) { Hanami.app["operations.registrations.import_avatar"] }
  let(:s3_client) { Hanami.app["s3.client"] }
  let(:user_id) { 1 }

  describe "#call" do
    context "when avatar_url is empty or nil" do
      it "returns a no_url failure for nil" do
        expect(operation.call(user_id:, avatar_url: nil)).to be_failure
          .and have_attributes(failure: :no_url)
      end

      it "returns a no_url failure for empty string" do
        expect(operation.call(user_id:, avatar_url: "")).to be_failure
          .and have_attributes(failure: :no_url)
      end
    end

    context "when avatar_url is not HTTPS" do
      it "returns a fetch_failed failure for http" do
        expect(operation.call(user_id:, avatar_url: "http://example.com/avatar.jpg")).to be_failure
          .and have_attributes(failure: :fetch_failed)
      end

      it "returns a fetch_failed failure for file scheme" do
        expect(operation.call(user_id:, avatar_url: "file:///etc/passwd")).to be_failure
          .and have_attributes(failure: :fetch_failed)
      end
    end
  end
end
