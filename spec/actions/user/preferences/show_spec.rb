# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::User::Preferences::Show do
  let(:load_preferences) { instance_double(PastaAtlas::Operations::User::Preferences::Load) }
  let(:verify_ownership) { instance_double(PastaAtlas::Operations::User::VerifyOwnership) }
  let(:action) { PastaAtlas::Actions::User::Preferences::Show.new(load_preferences:, verify_ownership:) }

  let(:user) { double("User", id: 1, name: "sakuro") }
  let(:preference) { double("UserPreference", timezone: "Asia/Tokyo", locale: "ja", relative_timestamps: true) }

  context "when not logged in" do
    let(:env) { {"rack.session" => {}, :user_name => "sakuro"} }

    before do
      allow(verify_ownership).to receive(:call)
        .with(user_id: nil, user_name: "sakuro")
        .and_return(Failure(:forbidden))
    end

    it "returns 403" do
      response = action.call(env)

      expect(response.status).to eq(403)
    end
  end

  context "when logged in as a different user" do
    let(:env) { {"rack.session" => {"user_id" => 2}, :user_name => "sakuro"} }

    before do
      allow(verify_ownership).to receive(:call)
        .with(user_id: 2, user_name: "sakuro")
        .and_return(Failure(:forbidden))
    end

    it "returns 403" do
      response = action.call(env)

      expect(response.status).to eq(403)
    end
  end

  context "when logged in as the owner" do
    let(:env) { {"rack.session" => {"user_id" => 1}, :user_name => "sakuro"} }

    before do
      allow(verify_ownership).to receive(:call)
        .with(user_id: 1, user_name: "sakuro")
        .and_return(Success(user))
      allow(load_preferences).to receive(:call)
        .with(user_id: 1, viewer_id: 1)
        .and_return(Success(preference))
    end

    it "returns 200 with preferences JSON" do
      response = action.call(env)

      expect(response.status).to eq(200)
      body = JSON.parse(response.body.join)
      expect(body).to include(
        "timezone" => "Asia/Tokyo",
        "locale" => "ja",
        "relative_timestamps" => true
      )
      expect(body["timezone_identifiers"]).to be_an(Array).and include("UTC")
      expect(body["supported_locales"]).to be_an(Array).and include("ja")
    end
  end
end
