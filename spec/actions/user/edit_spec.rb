# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::User::Edit, :action_env do
  let(:verify_ownership) { instance_double(PastaAtlas::Operations::User::VerifyOwnership) }
  let(:load_profile) { instance_double(PastaAtlas::Operations::User::Profile::Load) }
  let(:load_preferences) { instance_double(PastaAtlas::Operations::User::Preferences::Load) }
  let(:load_credentials) { instance_double(PastaAtlas::Operations::User::Credentials::Load) }
  let(:action) { PastaAtlas::Actions::User::Edit.new(verify_ownership:, load_profile:, load_preferences:, load_credentials:) }

  let(:user) { double("User", id: 1, name: "sakuro") }
  let(:preference) { double("UserPreference", timezone: "Asia/Tokyo", locale: nil) }

  context "when logged in as the profile owner" do
    let(:env) { locale_env.merge("rack.session" => {"user_id" => 1}, :user_name => "sakuro") }

    before do
      allow(verify_ownership).to receive(:call)
        .with(user_id: 1, user_name: "sakuro").and_return(Success(user))
      allow(load_profile).to receive(:call)
        .with(user_id: 1).and_return(Success({display_name: "Sakuro", avatar_url: nil}))
      allow(load_preferences).to receive(:call)
        .with(user_id: 1, viewer_id: 1).and_return(Success(preference))
      allow(load_credentials).to receive(:call)
        .with(user_id: 1, viewer_id: 1).and_return(Success([]))
    end

    it "returns 200" do
      response = action.call(env)

      expect(response.status).to eq(200)
    end
  end

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
end
