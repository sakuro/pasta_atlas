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

    it "keeps a path" do
      expect(build("http://localhost:4566/bucket").cloudfront_base_url.to_s).to eq("http://localhost:4566/bucket")
    end

    it "rejects a trailing slash" do
      expect { build("https://cdn.example.com/") }.to raise_error(Hanami::Settings::InvalidSettingsError, /cloudfront_base_url/)
    end

    it "rejects a value that is not an http(s) URL" do
      expect { build("not a url") }.to raise_error(Hanami::Settings::InvalidSettingsError, /cloudfront_base_url/)
    end

    # The type is chosen when the class is loaded, so this runs against the type that allows HTTP.
    # The HTTPS requirement of production is covered by the CloudFrontBaseURL examples in types_spec.rb.
    it "accepts an http URL in the test environment" do
      expect(build("http://localhost:4566/bucket").cloudfront_base_url).to be_a(URI::HTTP)
    end
  end
end
