# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::API::Auth::Current, :action_env do
  let(:user_repo) { instance_double(PastaAtlas::Repos::UserRepo) }
  let(:user_profile_repo) { instance_double(PastaAtlas::Repos::UserProfileRepo) }
  let(:user_preference_repo) { instance_double(PastaAtlas::Repos::UserPreferenceRepo) }
  let(:settings) { double("Settings", cloudfront_base_url: "https://cdn.example.com") }
  let(:action) do
    PastaAtlas::Actions::API::Auth::Current.new(
      user_repo:,
      user_profile_repo:,
      user_preference_repo:,
      settings:
    )
  end

  context "when no user is in session" do
    it "returns 200 with null user and guest preferences" do
      response = action.call(locale_env)

      expect(response.status).to eq(200)
      body = JSON.parse(response.body.join)
      expect(body["user"]).to be_nil
      expect(body["preferences"]).to include(
        "locale" => nil,
        "timezone" => "UTC",
        "relative_timestamps" => false
      )
    end
  end

  context "when a user is in session" do
    let(:env) { locale_env.merge("rack.session" => {"user_id" => 42}) }
    let(:user) { double("User", name: "sakuro") }
    let(:profile) do
      double("UserProfile", display_name: "Sakuro Ozawa", avatar_s3_key: "avatars/42/abc.jpg")
    end
    let(:preference) do
      double("UserPreference", locale: "ja", timezone: "Asia/Tokyo", relative_timestamps: true)
    end

    before do
      allow(user_repo).to receive(:find_by_id).with(42).and_return(user)
      allow(user_profile_repo).to receive(:find_by_user_id).with(42).and_return(profile)
      allow(user_preference_repo).to receive(:find_by_user_id).with(42).and_return(preference)
    end

    it "returns 200 with user data and preferences" do
      response = action.call(env)

      expect(response.status).to eq(200)
      body = JSON.parse(response.body.join)
      expect(body["user"]).to include(
        "name" => "sakuro",
        "display_name" => "Sakuro Ozawa",
        "avatar_url" => "https://cdn.example.com/avatars/42/abc.jpg"
      )
      expect(body["preferences"]).to include(
        "locale" => "ja",
        "timezone" => "Asia/Tokyo",
        "relative_timestamps" => true
      )
    end

    context "when the profile has no display name" do
      let(:profile) { double("UserProfile", display_name: nil, avatar_s3_key: nil) }

      it "falls back to the username" do
        response = action.call(env)

        body = JSON.parse(response.body.join)
        expect(body["user"]).to include("display_name" => "sakuro")
      end
    end

    context "when the profile has no avatar" do
      let(:profile) { double("UserProfile", display_name: "Sakuro", avatar_s3_key: nil) }

      it "returns null avatar_url" do
        response = action.call(env)

        body = JSON.parse(response.body.join)
        expect(body["user"]["avatar_url"]).to be_nil
      end
    end
  end

  context "when the user record is missing" do
    let(:env) { locale_env.merge("rack.session" => {"user_id" => 999}) }

    before do
      allow(user_repo).to receive(:find_by_id).with(999).and_raise(ROM::TupleCountMismatchError)
    end

    it "returns 200 with null user and guest preferences" do
      response = action.call(env)

      expect(response.status).to eq(200)
      body = JSON.parse(response.body.join)
      expect(body["user"]).to be_nil
      expect(body["preferences"]).to include("locale" => nil, "timezone" => "UTC")
    end
  end
end
