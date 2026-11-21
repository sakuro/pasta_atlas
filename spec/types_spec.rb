# frozen_string_literal: true

RSpec.describe PastaAtlas::Types do
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
end
