# frozen_string_literal: true

RSpec.describe PastaAtlas::Settings do
  def build(cloudfront_base_url)
    PastaAtlas::Settings.new(
      session_secret: "secret",
      discord_client_id: "id",
      discord_client_secret: "secret",
      github_client_id: "id",
      github_client_secret: "secret",
      steam_web_api_key: "key",
      s3_bucket: "bucket",
      sqs_s3_cleanup_queue_url: "http://localhost:4566/000000000000/queue",
      cloudfront_base_url:
    )
  end

  describe "cloudfront_base_url" do
    it "returns a URI" do
      expect(build("https://cdn.example.com").cloudfront_base_url).to be_a(URI::HTTPS)
    end

    it "keeps the value as it is, including a path and a trailing slash" do
      expect(build("http://localhost:4566/bucket/").cloudfront_base_url.to_s).to eq("http://localhost:4566/bucket/")
    end

    it "rejects a value that is not an http(s) URL" do
      expect { build("not a url") }.to raise_error(Hanami::Settings::InvalidSettingsError, /cloudfront_base_url/)
    end

    context "when HTTP is allowed (development and test)" do
      it "accepts an http URL" do
        expect(build("http://localhost:4566/bucket").cloudfront_base_url).to be_a(URI::HTTP)
      end
    end

    context "when HTTPS is required (production)" do
      before do
        allow(Hanami).to receive(:env?).and_call_original
        allow(Hanami).to receive(:env?).with(:development, :test).and_return(false)
      end

      it "accepts an https URL" do
        expect(build("https://cdn.example.com").cloudfront_base_url).to be_a(URI::HTTPS)
      end

      it "rejects an http URL" do
        expect { build("http://cdn.example.com") }.to raise_error(Hanami::Settings::InvalidSettingsError, /cloudfront_base_url/)
      end
    end
  end
end
