# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::User::Preferences::Update do
  let(:supported_locales) { %w[en ja] }
  let(:user_preference_repo) { instance_double(PastaAtlas::Repos::UserPreferenceRepo) }
  let(:operation) { PastaAtlas::Operations::User::Preferences::Update.new(supported_locales:, user_preference_repo:) }

  let(:user) { double("User", id: 1) }

  before do
    allow(user_preference_repo).to receive(:update_preferences)
  end

  describe "#call" do
    context "when normalizing timezone" do
      it "stores nil as-is" do
        operation.call(user:, timezone: nil, locale: nil, relative_timestamps: false)
        expect(user_preference_repo).to have_received(:update_preferences).with(1, hash_including(timezone: nil))
      end

      it "normalizes empty string to nil" do
        operation.call(user:, timezone: "", locale: nil, relative_timestamps: false)
        expect(user_preference_repo).to have_received(:update_preferences).with(1, hash_including(timezone: nil))
      end

      it "stores a valid timezone as-is" do
        operation.call(user:, timezone: "Asia/Tokyo", locale: nil, relative_timestamps: false)
        expect(user_preference_repo).to have_received(:update_preferences).with(1, hash_including(timezone: "Asia/Tokyo"))
      end

      it "normalizes an invalid timezone to nil" do
        operation.call(user:, timezone: "Not/ATimezone", locale: nil, relative_timestamps: false)
        expect(user_preference_repo).to have_received(:update_preferences).with(1, hash_including(timezone: nil))
      end
    end

    context "when normalizing locale" do
      it "stores nil as-is" do
        operation.call(user:, timezone: "Asia/Tokyo", locale: nil, relative_timestamps: false)
        expect(user_preference_repo).to have_received(:update_preferences).with(1, hash_including(locale: nil))
      end

      it "normalizes empty string to nil" do
        operation.call(user:, timezone: "Asia/Tokyo", locale: "", relative_timestamps: false)
        expect(user_preference_repo).to have_received(:update_preferences).with(1, hash_including(locale: nil))
      end

      it "stores a supported locale as-is" do
        operation.call(user:, timezone: "Asia/Tokyo", locale: "ja", relative_timestamps: false)
        expect(user_preference_repo).to have_received(:update_preferences).with(1, hash_including(locale: "ja"))
      end

      it "normalizes an unsupported locale to nil" do
        operation.call(user:, timezone: "Asia/Tokyo", locale: "xx", relative_timestamps: false)
        expect(user_preference_repo).to have_received(:update_preferences).with(1, hash_including(locale: nil))
      end
    end
  end
end
