# frozen_string_literal: true

RSpec.describe PastaAtlas::Resolvers::LocaleResolver do
  let(:load_preferences) { instance_double(PastaAtlas::Operations::User::Preferences::Load) }
  let(:supported_locales) { %w[cs en ja ko zh-CN zh-TW] }
  let(:resolver) { PastaAtlas::Resolvers::LocaleResolver.new(load_preferences:, supported_locales:) }

  describe "#call" do
    context "when user_id is nil" do
      context "with no Accept-Language header" do
        it "returns 'en'" do
          expect(resolver.call(user_id: nil)).to eq("en")
        end
      end

      context "with an exact supported locale" do
        it "returns 'ja'" do
          expect(resolver.call(user_id: nil, accept_language: "ja")).to eq("ja")
        end
      end

      context "with a region-qualified locale" do
        it "returns the language part" do
          expect(resolver.call(user_id: nil, accept_language: "ja-JP")).to eq("ja")
        end
      end

      context "with an unsupported locale" do
        it "falls back to 'en'" do
          expect(resolver.call(user_id: nil, accept_language: "xx")).to eq("en")
        end
      end

      context "with multiple locales and q-values" do
        it "returns the highest-quality supported locale" do
          expect(resolver.call(user_id: nil, accept_language: "xx;q=0.9,ja;q=0.8,en;q=0.7")).to eq("ja")
        end
      end
    end

    context "when user_id is present" do
      let(:preference) { double("UserPreference", locale: "ja") }

      before { allow(load_preferences).to receive(:call).with(user_id: 42).and_return(Success(preference)) }

      it "returns the stored locale" do
        expect(resolver.call(user_id: 42)).to eq("ja")
      end
    end
  end
end
