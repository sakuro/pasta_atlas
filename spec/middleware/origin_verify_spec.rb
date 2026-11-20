# frozen_string_literal: true

require "rack/mock"

RSpec.describe PastaAtlas::Middleware::OriginVerify do
  let(:app) { ->(_env) { [200, {"content-type" => "text/plain"}, ["ok"]] } }
  let(:request) { Rack::MockRequest.new(PastaAtlas::Middleware::OriginVerify.new(app, secret: "s3cret")) }

  describe ".new" do
    it "rejects an empty secret" do
      expect { PastaAtlas::Middleware::OriginVerify.new(app, secret: "") }.to raise_error(ArgumentError)
    end
  end

  describe "#call" do
    it "passes requests carrying the secret header" do
      expect(request.get("/", "HTTP_X_ORIGIN_VERIFY" => "s3cret").status).to eq(200)
    end

    it "rejects requests without the header" do
      expect(request.get("/").status).to eq(403)
    end

    it "rejects requests with a wrong secret" do
      expect(request.get("/", "HTTP_X_ORIGIN_VERIFY" => "wrong").status).to eq(403)
    end

    it "lets the readiness check path through without the header" do
      expect(request.get("/up").status).to eq(200)
    end
  end
end
