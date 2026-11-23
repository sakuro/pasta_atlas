# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::API::Users::Preferences::Show do
  let(:load_preferences) { instance_double(PastaAtlas::Operations::User::Preferences::Load) }
  let(:verify_ownership) { instance_double(PastaAtlas::Operations::User::VerifyOwnership) }
  let(:user_resolver) { instance_double(PastaAtlas::Resolvers::UserResolver) }
  let(:action) { PastaAtlas::Actions::API::Users::Preferences::Show.new(load_preferences:, verify_ownership:, user_resolver:) }

  let(:guest) { double("User", id: 0, name: "guest") }
  let(:user) { double("User", id: 1, name: "wube") }
  let(:preference) { double("UserPreference", timezone: "Asia/Tokyo", locale: "ja", relative_timestamps: true) }

  context "when not logged in" do
    let(:env) { {"rack.session" => {}, :user_name => "wube"} }

    before do
      allow(user_resolver).to receive(:call).with(nil).and_return(guest)
      allow(verify_ownership).to receive(:call)
        .with(current_user: guest, user_name: "wube")
        .and_return(Failure(:forbidden))
    end

    it "returns 403" do
      response = action.call(env)

      expect(response.status).to eq(403)
      expect(response).to conform_to_openapi("GET /api/v1/users/{user_name}/preferences")
    end
  end

  context "when logged in as a different user" do
    let(:other_user) { double("User", id: 2, name: "bob") }
    let(:env) { {"rack.session" => {"user_id" => 2}, :user_name => "wube"} }

    before do
      allow(user_resolver).to receive(:call).with(2).and_return(other_user)
      allow(verify_ownership).to receive(:call)
        .with(current_user: other_user, user_name: "wube")
        .and_return(Failure(:forbidden))
    end

    it "returns 403" do
      response = action.call(env)

      expect(response.status).to eq(403)
      expect(response).to conform_to_openapi("GET /api/v1/users/{user_name}/preferences")
    end
  end

  context "when logged in as the owner" do
    let(:env) { {"rack.session" => {"user_id" => 1}, :user_name => "wube"} }

    before do
      allow(user_resolver).to receive(:call).with(1).and_return(user)
      allow(verify_ownership).to receive(:call)
        .with(current_user: user, user_name: "wube")
        .and_return(Success(user))
      allow(load_preferences).to receive(:call)
        .with(user_id: 1)
        .and_return(Success(preference))
    end

    it "returns 200 with preferences JSON" do
      response = action.call(env)

      expect(response.status).to eq(200)
      expect(response).to conform_to_openapi("GET /api/v1/users/{user_name}/preferences")
      body = JSON.parse(response.body.join)
      expect(body).to include(
        "timezone" => "Asia/Tokyo",
        "locale" => "ja",
        "relative_timestamps" => true
      )
      expect(body["timezone_identifiers"]).to be_an(Array).and include("UTC")
    end
  end
end
