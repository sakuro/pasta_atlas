# frozen_string_literal: true

RSpec.describe PastaAtlas::Types do
  shared_examples "a base URL" do
    {
      "a trailing slash" => "https://cdn.example.com/",
      "a trailing slash after a path" => "https://cdn.example.com/bucket/",
      "a query" => "https://cdn.example.com?x=1",
      "a fragment" => "https://cdn.example.com#top"
    }.each do |description, value|
      it "rejects #{description}" do
        expect { type[value] }.to raise_error(Dry::Types::CoercionError, /must not end with a slash or have a query or a fragment/)
      end
    end

    it "keeps a path without a trailing slash" do
      expect(type["https://cdn.example.com/bucket"].to_s).to eq("https://cdn.example.com/bucket")
    end

    ["", "https://", "not a url", nil].each do |value|
      it "rejects #{value.inspect}" do
        expect { type[value] }.to raise_error(Dry::Types::CoercionError)
      end
    end
  end

  describe "HTTPURL" do
    let(:type) { PastaAtlas::Types::HTTPURL }

    it "returns a URI::HTTPS for an https URL" do
      expect(type["https://cdn.example.com"]).to be_a(URI::HTTPS)
    end

    it "returns a URI::HTTP for an http URL" do
      expect(type["http://localhost:4566/bucket"]).to be_a(URI::HTTP).and have_attributes(host: "localhost", port: 4566, path: "/bucket")
    end

    it "keeps a trailing slash" do
      expect(type["https://cdn.example.com/"].to_s).to eq("https://cdn.example.com/")
    end

    ["", "ftp://cdn.example.com", "https://", "cdn.example.com", nil].each do |value|
      it "rejects #{value.inspect}" do
        expect { type[value] }.to raise_error(Dry::Types::CoercionError, /must be an http\(s\) URL with a host/)
      end
    end
  end

  describe "HTTPSURL" do
    let(:type) { PastaAtlas::Types::HTTPSURL }

    it "returns a URI::HTTPS for an https URL" do
      expect(type["https://cdn.example.com"]).to be_a(URI::HTTPS)
    end

    it "rejects an http URL" do
      expect { type["http://cdn.example.com"] }.to raise_error(Dry::Types::ConstraintError)
    end

    it "rejects a value that is not a URL" do
      expect { type["not a url"] }.to raise_error(Dry::Types::CoercionError)
    end
  end

  describe "CloudFrontBaseURL" do
    let(:type) { PastaAtlas::Types::CloudFrontBaseURL }

    it_behaves_like "a base URL"

    it "returns a URI::HTTPS for an https URL" do
      expect(type["https://d111111abcdef8.cloudfront.net"]).to be_a(URI::HTTPS)
    end

    it "rejects an http URL" do
      expect { type["http://cdn.example.com"] }.to raise_error(Dry::Types::ConstraintError)
    end
  end

  describe "LocalCloudFrontBaseURL" do
    let(:type) { PastaAtlas::Types::LocalCloudFrontBaseURL }

    it_behaves_like "a base URL"

    it "accepts the path-style URL of Floci" do
      expect(type["http://localhost:4566/pasta-atlas-local-mapshots"]).to be_a(URI::HTTP).and have_attributes(host: "localhost", port: 4566, path: "/pasta-atlas-local-mapshots")
    end

    it "accepts an https URL" do
      expect(type["https://cdn.example.com"]).to be_a(URI::HTTPS)
    end
  end
end
