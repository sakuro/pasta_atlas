# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::API::Auth::Current do
  let(:guest) { double("User", id: 0) }
  let(:find_user) { instance_double(PastaAtlas::Operations::User::FindById) }
  let(:load_profile) { instance_double(PastaAtlas::Operations::User::Profile::Load) }
  let(:load_preferences) { instance_double(PastaAtlas::Operations::User::Preferences::Load) }
  let(:action) do
    PastaAtlas::Actions::API::Auth::Current.new(guest:, find_user:, load_profile:, load_preferences:)
  end

  context "when no user is in session" do
    it "returns 200 with null user and guest preferences" do
      response = action.call({})

      expect(response.status).to eq(200)
      body = JSON.parse(response.body.join)
      expect(body["user"]).to be_nil
      expect(body["preferences"]).to include(
        "locale" => nil,
        "timezone" => nil,
        "relative_timestamps" => false
      )
    end
  end

  context "when a user is in session" do
    let(:env) { {"rack.session" => {"user_id" => 42}} }
    let(:user) { double("User", name: "sakuro") }
    let(:preference) do
      double("UserPreference", locale: "ja", timezone: "Asia/Tokyo", relative_timestamps: true)
    end

    before do
      allow(find_user).to receive(:call).with(user_id: 42).and_return(Success(user))
      allow(load_profile).to receive(:call).with(user_id: 42).and_return(Success({display_name: "Sakuro Ozawa", avatar_url: "https://cdn.example.com/avatars/42/abc.jpg"}))
      allow(load_preferences).to receive(:call).with(user_id: 42).and_return(Success(preference))
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
      before do
        allow(load_profile).to receive(:call).with(user_id: 42).and_return(Success({display_name: nil, avatar_url: nil}))
      end

      it "falls back to the username" do
        response = action.call(env)

        body = JSON.parse(response.body.join)
        expect(body["user"]).to include("display_name" => "sakuro")
      end
    end

    context "when the profile has no avatar" do
      before do
        allow(load_profile).to receive(:call).with(user_id: 42).and_return(Success({display_name: "Sakuro", avatar_url: nil}))
      end

      it "returns null avatar_url" do
        response = action.call(env)

        body = JSON.parse(response.body.join)
        expect(body["user"]["avatar_url"]).to be_nil
      end
    end
  end

  context "when the user record is missing" do
    let(:env) { {"rack.session" => {"user_id" => 999}} }

    before do
      allow(find_user).to receive(:call).with(user_id: 999).and_raise(ROM::TupleCountMismatchError)
    end

    it "returns 200 with null user and guest preferences" do
      response = action.call(env)

      expect(response.status).to eq(200)
      body = JSON.parse(response.body.join)
      expect(body["user"]).to be_nil
      expect(body["preferences"]).to include("locale" => nil, "timezone" => nil)
    end
  end
end
