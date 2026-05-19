# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::User::Profile::Update, :action_env do
  let(:verify_ownership) { instance_double(PastaAtlas::Operations::User::VerifyOwnership) }
  let(:user_profile_repo) { instance_double(PastaAtlas::Repos::UserProfileRepo) }
  let(:load_profile) { instance_double(PastaAtlas::Operations::User::Profile::Load) }
  let(:load_preferences) { instance_double(PastaAtlas::Operations::User::Preferences::Load) }
  let(:load_credentials) { instance_double(PastaAtlas::Operations::User::Credentials::Load) }
  let(:action) { PastaAtlas::Actions::User::Profile::Update.new(verify_ownership:, user_profile_repo:, load_profile:, load_preferences:, load_credentials:, edit_view:) }
  let(:edit_view) { Hanami.app["views.user.edit"] }

  let(:user) { double("User", id: 1, name: "sakuro") }

  context "when not logged in" do
    let(:env) { {"rack.session" => {}, :user_name => "sakuro", :display_name => "Sakuro"} }

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
    let(:env) { {"rack.session" => {"user_id" => 1}, :user_name => "bob", :display_name => "Sakuro"} }

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
    let(:env) { {"rack.session" => {"user_id" => 1}, :user_name => "sakuro", :display_name => "Sakuro"} }

    before do
      allow(verify_ownership).to receive(:call)
        .with(user_id: 1, user_name: "sakuro").and_return(Success(user))
      allow(user_profile_repo).to receive(:update_profile)
    end

    it "updates the profile and redirects to the user page" do
      response = action.call(env)

      expect(user_profile_repo).to have_received(:update_profile).with(1, display_name: "Sakuro")
      expect(response.status).to eq(302)
      expect(response.headers["Location"]).to eq("/@sakuro")
    end

    context "when display_name is blank" do
      let(:env) { {"rack.session" => {"user_id" => 1}, :user_name => "sakuro", :display_name => ""} }

      it "clears display name" do
        response = action.call(env)

        expect(user_profile_repo).to have_received(:update_profile).with(1, display_name: nil)
        expect(response.status).to eq(302)
      end
    end

    context "when display_name exceeds 64 grapheme clusters" do
      let(:env) { locale_env.merge("rack.session" => {"user_id" => 1}, :user_name => "sakuro", :display_name => "あ" * 65) }
      let(:preference) { double("UserPreference", timezone: "UTC", locale: nil) }

      before do
        allow(load_profile).to receive(:call).with(user_id: 1).and_return(Success({display_name: "Sakuro", avatar_url: nil}))
        allow(load_preferences).to receive(:call).with(user_id: 1, viewer_id: 1).and_return(Success(preference))
        allow(load_credentials).to receive(:call).with(user_id: 1, viewer_id: 1).and_return(Success([]))
      end

      it "re-renders the form without updating" do
        response = action.call(env)

        expect(user_profile_repo).not_to have_received(:update_profile)
        expect(response.status).to eq(200)
      end
    end
  end
end
