# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::API::Pages::Show, :action_env do
  let(:action) { PastaAtlas::Actions::API::Pages::Show.new }

  context "with an unknown slug" do
    it "returns 404" do
      response = action.call(locale_env.merge(slug: "unknown"))

      expect(response.status).to eq(404)
    end
  end

  context "with a known slug" do
    it "returns 200 with HTML content" do
      response = action.call(locale_env.merge(slug: "about"))

      expect(response.status).to eq(200)
      body = JSON.parse(response.body.join)
      expect(body["content"]).to include("<section")
      expect(body["content"]).to include("data-l10n-id")
    end

    context "with a Japanese locale" do
      it "returns Japanese content" do
        response = action.call(locale_env("ja").merge(slug: "about"))

        expect(response.status).to eq(200)
        body = JSON.parse(response.body.join)
        expect(body["content"]).to include("について")
      end
    end
  end
end
