# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::User::Profile::Update, :action_env do
  let(:list_recent_maps) { instance_double(PastaAtlas::Operations::Maps::ListRecentByUser) }
  let(:load_credentials) { instance_double(PastaAtlas::Operations::User::Credentials::Load) }
  let(:load_preferences) { instance_double(PastaAtlas::Operations::User::Preferences::Load) }
  let(:load_profile) { instance_double(PastaAtlas::Operations::User::Profile::Load) }
  let(:show_view) { Hanami.app["views.user.show"] }
  let(:update_profile) { instance_double(PastaAtlas::Operations::User::Profile::Update) }
  let(:action) { PastaAtlas::Actions::User::Profile::Update.new(list_recent_maps:, load_credentials:, load_preferences:, load_profile:, show_view:, update_profile:) }

  let(:user) { double("User", id: 1, name: "sakuro") }

  context "when not logged in" do
    let(:env) { {"rack.session" => {}, :user_name => "sakuro", :display_name => "Sakuro"} }

    before do
      allow(update_profile).to receive(:call)
        .with(hash_including(user_id: nil, user_name: "sakuro"))
        .and_return(Failure(:forbidden))
    end

    it "returns 403" do
      response = action.call(env)

      expect(response.status).to eq(403)
    end
  end

  context "when logged in as a different user" do
    let(:env) { {"rack.session" => {"user_id" => 1}, :user_name => "bob", :display_name => "Sakuro"} }

    before do
      allow(update_profile).to receive(:call)
        .with(hash_including(user_id: 1, user_name: "bob"))
        .and_return(Failure(:forbidden))
    end

    it "returns 403" do
      response = action.call(env)

      expect(response.status).to eq(403)
    end
  end

  context "when logged in" do
    let(:env) { {"rack.session" => {"user_id" => 1}, :user_name => "sakuro", :display_name => "Sakuro"} }

    before do
      allow(update_profile).to receive(:call)
        .with(hash_including(user_id: 1, user_name: "sakuro"))
        .and_return(Success(user))
    end

    it "updates the profile and redirects to the user page" do
      response = action.call(env)

      expect(response.status).to eq(302)
      expect(response.headers["Location"]).to eq("/@sakuro")
    end

    context "when display_name is blank" do
      let(:env) { {"rack.session" => {"user_id" => 1}, :user_name => "sakuro", :display_name => ""} }

      it "redirects to the user page" do
        response = action.call(env)

        expect(response.status).to eq(302)
      end
    end

    context "when display_name is invalid" do
      let(:env) { locale_env.merge("rack.session" => {"user_id" => 1}, :user_name => "sakuro", :display_name => "あ" * 65) }
      let(:preference) { double("UserPreference", timezone: "UTC", locale: nil) }

      before do
        allow(update_profile).to receive(:call)
          .with(hash_including(user_id: 1, user_name: "sakuro"))
          .and_return(Failure([:invalid, "Display name must be 64 characters or fewer."]))
        allow(load_profile).to receive(:call).with(user_id: 1).and_return(Success({display_name: "Sakuro", avatar_url: nil}))
        allow(load_preferences).to receive(:call).with(user_id: 1, viewer_id: 1).and_return(Success(preference))
        allow(load_credentials).to receive(:call).with(user_id: 1, viewer_id: 1).and_return(Success([]))
        allow(list_recent_maps).to receive(:call).with(user_id: 1, user_info: anything).and_return(Success([]))
      end

      it "re-renders the form" do
        response = action.call(env)

        expect(response.status).to eq(200)
      end
    end
  end
end
