# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::User::Preferences::Update do
  let(:verify_ownership) { instance_double(PastaAtlas::Operations::User::VerifyOwnership) }
  let(:user_preference_repo) { instance_double(PastaAtlas::Repos::UserPreferenceRepo) }
  let(:action) { PastaAtlas::Actions::User::Preferences::Update.new(verify_ownership:, user_preference_repo:) }

  let(:user) { double("User", id: 1, name: "sakuro") }

  context "when not logged in" do
    let(:env) { {"rack.session" => {}, :user_name => "sakuro"} }

    before do
      allow(verify_ownership).to receive(:call)
        .with(user_id: nil, user_name: "sakuro").and_return(Failure(:forbidden))
    end

    it "returns 403" do
      response = action.call(env)

      expect(response.status).to eq(403)
    end
  end

  context "when logged in as a different user" do
    let(:env) { {"rack.session" => {"user_id" => 1}, :user_name => "bob"} }

    before do
      allow(verify_ownership).to receive(:call)
        .with(user_id: 1, user_name: "bob").and_return(Failure(:forbidden))
    end

    it "returns 403" do
      response = action.call(env)

      expect(response.status).to eq(403)
    end
  end

  context "when logged in" do
    let(:env) { {"rack.session" => {"user_id" => 1}, :user_name => "sakuro", :timezone => "Asia/Tokyo", :locale => "ja"} }

    before do
      allow(verify_ownership).to receive(:call)
        .with(user_id: 1, user_name: "sakuro").and_return(Success(user))
      allow(user_preference_repo).to receive(:update_preferences)
    end

    it "updates preferences and redirects to the user page" do
      response = action.call(env)

      expect(user_preference_repo).to have_received(:update_preferences).with(1, timezone: "Asia/Tokyo", locale: "ja")
      expect(response.status).to eq(302)
      expect(response.headers["Location"]).to eq("/@sakuro")
    end

    context "when timezone is invalid" do
      let(:env) { {"rack.session" => {"user_id" => 1}, :user_name => "sakuro", :timezone => "Invalid/Zone", :locale => ""} }

      it "falls back to UTC and clears locale" do
        response = action.call(env)

        expect(user_preference_repo).to have_received(:update_preferences).with(1, timezone: "UTC", locale: nil)
        expect(response.status).to eq(302)
      end
    end

    context "when locale is unsupported" do
      let(:env) { {"rack.session" => {"user_id" => 1}, :user_name => "sakuro", :timezone => "UTC", :locale => "fr"} }

      it "saves nil for locale" do
        action.call(env)

        expect(user_preference_repo).to have_received(:update_preferences).with(1, timezone: "UTC", locale: nil)
      end
    end
  end
end
