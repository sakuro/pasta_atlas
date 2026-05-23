# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::User::Show, :action_env do
  let(:find_by_name) { instance_double(PastaAtlas::Operations::User::FindByName) }
  let(:list_recent_maps) { instance_double(PastaAtlas::Operations::Maps::ListRecentByUser) }
  let(:load_credentials) { instance_double(PastaAtlas::Operations::User::Credentials::Load) }
  let(:load_preferences) { instance_double(PastaAtlas::Operations::User::Preferences::Load) }
  let(:load_profile) { instance_double(PastaAtlas::Operations::User::Profile::Load) }
  let(:action) { PastaAtlas::Actions::User::Show.new(find_by_name:, list_recent_maps:, load_credentials:, load_preferences:, load_profile:) }

  let(:user) { double("User", id: 1, name: "sakuro", guest?: false) }
  let(:user_info) { PastaAtlas::Values::UserInfo[name: "sakuro", display_name: "Sakuro", avatar_url: nil] }
  let(:map_info) { double("MapInfo", ulid: "01MAP1", display_name: "Map 1", user_info:, thumbnail_url: nil, metadata_url: nil, updated_at: nil) }

  before do
    allow(load_profile).to receive(:call).with(user_id: 1).and_return(Success({display_name: "Sakuro", avatar_url: nil}))
    allow(list_recent_maps).to receive(:call).with(user_id: 1, user_info: anything).and_return(Success([map_info]))
  end

  context "when the viewer is not logged in" do
    let(:env) { locale_env.merge("rack.session" => {}, :user_name => "sakuro") }

    before { allow(find_by_name).to receive(:call).with(user_name: "sakuro").and_return(Success(user)) }

    it "returns 200" do
      response = action.call(env)

      expect(response.status).to eq(200)
    end
  end

  context "when the viewer is the profile owner" do
    let(:env) { locale_env.merge("rack.session" => {"user_id" => 1}, :user_name => "sakuro") }
    let(:preference) { double("UserPreference", timezone: "Asia/Tokyo", locale: nil, relative_timestamps: false) }

    before do
      allow(find_by_name).to receive(:call).with(user_name: "sakuro").and_return(Success(user))
      allow(load_preferences).to receive(:call).with(user_id: 1, viewer_id: 1).and_return(Success(preference))
      allow(load_credentials).to receive(:call).with(user_id: 1, viewer_id: 1).and_return(Success([]))
    end

    it "returns 200" do
      response = action.call(env)

      expect(response.status).to eq(200)
    end
  end

  context "when the viewer is a different logged-in user" do
    let(:env) { locale_env.merge("rack.session" => {"user_id" => 2}, :user_name => "sakuro") }

    before do
      allow(find_by_name).to receive(:call).with(user_name: "sakuro").and_return(Success(user))
    end

    it "returns 200" do
      response = action.call(env)

      expect(response.status).to eq(200)
    end

    it "fetches recent maps for the user" do
      action.call(env)

      expect(list_recent_maps).to have_received(:call).with(user_id: 1, user_info: anything)
    end
  end

  context "when the requested user is the guest account" do
    let(:guest) { double("User", id: 999, name: "guest", guest?: true) }
    let(:env) { locale_env.merge("rack.session" => {}, :user_name => "guest") }

    before { allow(find_by_name).to receive(:call).with(user_name: "guest").and_return(Success(guest)) }

    it "returns 404" do
      response = action.call(env)

      expect(response.status).to eq(404)
    end
  end

  context "when the user does not exist" do
    let(:env) { locale_env.merge("rack.session" => {}, :user_name => "nobody") }

    before { allow(find_by_name).to receive(:call).with(user_name: "nobody").and_return(Failure(:not_found)) }

    it "returns 404" do
      response = action.call(env)

      expect(response.status).to eq(404)
    end
  end
end
