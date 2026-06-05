# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::API::Pages::Show do
  let(:locale_resolver) { instance_double(PastaAtlas::Resolvers::LocaleResolver) }
  let(:action) { PastaAtlas::Actions::API::Pages::Show.new(locale_resolver:) }

  before { allow(locale_resolver).to receive(:call).and_return("en") }

  context "with an unknown slug" do
    it "returns 404" do
      response = action.call({slug: "unknown"})

      expect(response.status).to eq(404)
    end
  end

  context "with a known slug" do
    it "returns English content by default" do
      response = action.call({slug: "about"})

      expect(response.status).to eq(200)
      body = JSON.parse(response.body.join)
      expect(body["content"]).to include("<section")
      expect(body["content"]).to include("data-l10n-id")
    end

    context "when the resolver returns Japanese" do
      before { allow(locale_resolver).to receive(:call).and_return("ja") }

      it "returns Japanese content" do
        response = action.call({slug: "about"})

        expect(response.status).to eq(200)
        body = JSON.parse(response.body.join)
        expect(body["content"]).to include("について")
      end
    end
  end
end
