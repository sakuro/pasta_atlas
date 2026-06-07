# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::Registrations::ImportAvatar do
  let(:operation) { Hanami.app["operations.registrations.import_avatar"] }
  let(:s3_client) { Hanami.app["s3.client"] }
  let(:user) { double("User", name: "alice") }

  describe "#call" do
    context "when avatar_url is empty or nil" do
      it "returns a no_url failure for nil" do
        expect(operation.call(user:, avatar_url: nil)).to be_failure
          .and have_attributes(failure: :no_url)
      end

      it "returns a no_url failure for empty string" do
        expect(operation.call(user:, avatar_url: "")).to be_failure
          .and have_attributes(failure: :no_url)
      end
    end

    context "when avatar_url is not HTTPS" do
      it "returns a fetch_failed failure for http" do
        expect(operation.call(user:, avatar_url: "http://example.com/avatar.jpg")).to be_failure
          .and have_attributes(failure: :fetch_failed)
      end

      it "returns a fetch_failed failure for file scheme" do
        expect(operation.call(user:, avatar_url: "file:///etc/passwd")).to be_failure
          .and have_attributes(failure: :fetch_failed)
      end
    end

    context "when avatar_url has a disallowed host" do
      it "returns a fetch_failed failure" do
        expect(operation.call(user:, avatar_url: "https://evil.example.com/avatar.jpg")).to be_failure
          .and have_attributes(failure: :fetch_failed)
      end
    end

    context "when the server redirects to a disallowed host" do
      let(:http) { instance_double(Net::HTTP) }
      let(:redirect_response) do
        double("redirect_response").tap do |r|
          allow(r).to receive(:is_a?).with(Net::HTTPRedirection).and_return(true)
          allow(r).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
          allow(r).to receive(:[]).with("Location").and_return("https://evil.example.com/avatar.jpg")
        end
      end

      before do
        allow(Net::HTTP).to receive(:start).and_yield(http)
        allow(http).to receive(:get).and_return(redirect_response)
      end

      it "returns a fetch_failed failure" do
        expect(operation.call(user:, avatar_url: "https://avatars.githubusercontent.com/u/1.png")).to be_failure
          .and have_attributes(failure: :fetch_failed)
      end
    end

    context "when the response Content-Length exceeds the limit" do
      let(:http) { instance_double(Net::HTTP) }
      let(:oversized_response) do
        double("oversized_response").tap do |r|
          allow(r).to receive(:is_a?).with(Net::HTTPRedirection).and_return(false)
          allow(r).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          allow(r).to receive(:[]).with("Content-Length").and_return(((5 * 1024 * 1024) + 1).to_s)
        end
      end

      before do
        allow(Net::HTTP).to receive(:start).and_yield(http)
        allow(http).to receive(:get).and_return(oversized_response)
      end

      it "returns a fetch_failed failure" do
        expect(operation.call(user:, avatar_url: "https://avatars.githubusercontent.com/u/1.png")).to be_failure
          .and have_attributes(failure: :fetch_failed)
      end
    end

    context "when the response body exceeds the limit" do
      let(:http) { instance_double(Net::HTTP) }
      let(:oversized_response) do
        double("oversized_response").tap do |r|
          allow(r).to receive(:is_a?).with(Net::HTTPRedirection).and_return(false)
          allow(r).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          allow(r).to receive(:[]).with("Content-Length").and_return(nil)
          allow(r).to receive(:body).and_return("x" * ((5 * 1024 * 1024) + 1))
        end
      end

      before do
        allow(Net::HTTP).to receive(:start).and_yield(http)
        allow(http).to receive(:get).and_return(oversized_response)
      end

      it "returns a fetch_failed failure" do
        expect(operation.call(user:, avatar_url: "https://avatars.githubusercontent.com/u/1.png")).to be_failure
          .and have_attributes(failure: :fetch_failed)
      end
    end
  end
end
