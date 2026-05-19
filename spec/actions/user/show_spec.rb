# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::User::Show, :action_env do
  let(:user_repo) { instance_double(PastaAtlas::Repos::UserRepo) }
  let(:load_profile) { instance_double(PastaAtlas::Operations::User::Profile::Load) }
  let(:load_preferences) { instance_double(PastaAtlas::Operations::User::Preferences::Load) }
  let(:load_credentials) { instance_double(PastaAtlas::Operations::User::Credentials::Load) }
  let(:list_recent_maps) { instance_double(PastaAtlas::Operations::Maps::ListRecentByUser) }
  let(:action) { PastaAtlas::Actions::User::Show.new(user_repo:, load_profile:, load_preferences:, load_credentials:, list_recent_maps:) }

  let(:user) { double("User", id: 1, name: "sakuro") }
  let(:user_info) { PastaAtlas::Values::UserInfo[name: "sakuro", display_name: "Sakuro", avatar_url: nil] }
  let(:map_info) { double("MapInfo", ulid: "01MAP1", display_name: "Map 1", user_info:, thumbnail_url: nil, metadata_url: nil, updated_at: nil) }

  before do
    allow(user_repo).to receive(:find_by_name).with("sakuro").and_return(user)
    allow(load_profile).to receive(:call).with(user_id: 1).and_return(Success({display_name: "Sakuro", avatar_url: nil}))
    allow(list_recent_maps).to receive(:call).with(user_id: 1, user_info: anything).and_return(Success([map_info]))
  end

  context "when the user exists" do
    let(:env) { locale_env.merge("rack.session" => {}, :user_name => "sakuro") }

    before do
      allow(load_preferences).to receive(:call).with(user_id: 1, viewer_id: nil).and_return(Failure(:not_viewable))
      allow(load_credentials).to receive(:call).with(user_id: 1, viewer_id: nil).and_return(Failure(:not_viewable))
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

  context "when the user does not exist" do
    let(:env) { {"rack.session" => {}, :user_name => "nobody"} }

    before { allow(user_repo).to receive(:find_by_name).with("nobody").and_return(nil) }

    it "returns 404" do
      response = action.call(env)

      expect(response.status).to eq(404)
    end
  end
end
