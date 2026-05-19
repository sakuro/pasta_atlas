# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::User::Edit, :action_env do
  let(:verify_ownership) { instance_double(PastaAtlas::Operations::User::VerifyOwnership) }
  let(:user_profile_repo) { instance_double(PastaAtlas::Repos::UserProfileRepo) }
  let(:user_preference_repo) { instance_double(PastaAtlas::Repos::UserPreferenceRepo) }
  let(:credential_repo) { instance_double(PastaAtlas::Repos::CredentialRepo) }
  let(:settings) { double("Settings", cloudfront_base_url: "http://cdn.example.com") }
  let(:action) { PastaAtlas::Actions::User::Edit.new(verify_ownership:, user_profile_repo:, user_preference_repo:, credential_repo:, settings:) }

  let(:user) { double("User", id: 1, name: "sakuro") }
  let(:profile) { double("UserProfile", display_name: "Sakuro", avatar_s3_key: nil) }
  let(:preference) { double("UserPreference", timezone: "Asia/Tokyo", locale: nil) }

  context "when logged in as the profile owner" do
    let(:env) { locale_env.merge("rack.session" => {"user_id" => 1}, :user_name => "sakuro") }

    before do
      allow(verify_ownership).to receive(:call)
        .with(user_id: 1, user_name: "sakuro").and_return(Success(user))
      allow(user_profile_repo).to receive(:find_by_user_id).with(1).and_return(profile)
      allow(user_preference_repo).to receive(:find_by_user_id).with(1).and_return(preference)
      allow(credential_repo).to receive(:find_by_user_id).with(1).and_return([])
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
