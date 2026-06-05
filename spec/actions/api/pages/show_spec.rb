# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::API::Pages::Show do
  let(:load_preferences) { instance_double(PastaAtlas::Operations::User::Preferences::Load) }
  let(:action) { PastaAtlas::Actions::API::Pages::Show.new(load_preferences:) }

  context "with an unknown slug" do
    it "returns 404" do
      response = action.call({slug: "unknown"})

      expect(response.status).to eq(404)
    end
  end

  context "with a known slug" do
    context "with no Accept-Language (guest)" do
      it "returns English content" do
        response = action.call({slug: "about"})

        expect(response.status).to eq(200)
        body = JSON.parse(response.body.join)
        expect(body["content"]).to include("<section")
        expect(body["content"]).to include("data-l10n-id")
      end
    end

    context "with a Japanese Accept-Language (guest)" do
      it "returns Japanese content" do
        response = action.call({"HTTP_ACCEPT_LANGUAGE" => "ja", :slug => "about"})

        expect(response.status).to eq(200)
        body = JSON.parse(response.body.join)
        expect(body["content"]).to include("について")
      end
    end

    context "when logged in with a Japanese locale preference" do
      let(:preference) { double("UserPreference", locale: "ja") }

      before { allow(load_preferences).to receive(:call).with(user_id: 42).and_return(Success(preference)) }

      it "returns Japanese content" do
        response = action.call({"rack.session" => {"user_id" => 42}, :slug => "about"})

        expect(response.status).to eq(200)
        body = JSON.parse(response.body.join)
        expect(body["content"]).to include("について")
      end
    end
  end
end
