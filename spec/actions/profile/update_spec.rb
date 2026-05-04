# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::Profile::Update do
  let(:user_repo) { instance_double(PastaAtlas::Repos::UserRepo) }
  let(:user_profile_repo) { instance_double(PastaAtlas::Repos::UserProfileRepo) }
  let(:user_preference_repo) { instance_double(PastaAtlas::Repos::UserPreferenceRepo) }
  let(:action) { PastaAtlas::Actions::Profile::Update.new(user_repo:, user_profile_repo:, user_preference_repo:, edit_view:) }
  let(:edit_view) { Hanami.app["views.profile.edit"] }

  let(:user) { double("User", id: 1, name: "sakuro") }

  before do
    allow(user_repo).to receive(:find_by_id).with(1).and_return(user)
  end

  context "when not logged in" do
    let(:env) { {"rack.session" => {}, :user_name => "sakuro", :display_name => "Sakuro"} }

    it "returns 403" do
      response = action.call(env)

      expect(response.status).to eq(403)
    end
  end

  context "when logged in as a different user" do
    let(:env) { {"rack.session" => {"user_id" => 1}, :user_name => "bob", :display_name => "Sakuro"} }

    it "returns 403" do
      response = action.call(env)

      expect(response.status).to eq(403)
    end
  end

  context "when logged in" do
    let(:env) { {"rack.session" => {"user_id" => 1}, :user_name => "sakuro", :display_name => "Sakuro", :timezone => "Asia/Tokyo"} }

    before do
      allow(user_profile_repo).to receive(:update_profile)
      allow(user_preference_repo).to receive(:update_preferences)
    end

    it "updates the profile and redirects to the profile page" do
      response = action.call(env)

      expect(user_profile_repo).to have_received(:update_profile).with(1, display_name: "Sakuro")
      expect(user_preference_repo).to have_received(:update_preferences).with(1, timezone: "Asia/Tokyo")
      expect(response.status).to eq(302)
      expect(response.headers["Location"]).to eq("/@sakuro/profile")
    end

    context "when display_name is blank" do
      let(:env) { {"rack.session" => {"user_id" => 1}, :user_name => "sakuro", :display_name => "", :timezone => "Asia/Tokyo"} }

      it "clears display name" do
        response = action.call(env)

        expect(user_profile_repo).to have_received(:update_profile).with(1, display_name: nil)
        expect(user_preference_repo).to have_received(:update_preferences).with(1, timezone: "Asia/Tokyo")
        expect(response.status).to eq(302)
      end
    end

    context "when display_name exceeds 64 grapheme clusters" do
      let(:env) { {"rack.session" => {"user_id" => 1}, :user_name => "sakuro", :display_name => "あ" * 65, :timezone => "Asia/Tokyo"} }

      it "re-renders the form without updating" do
        response = action.call(env)

        expect(user_profile_repo).not_to have_received(:update_profile)
        expect(user_preference_repo).not_to have_received(:update_preferences)
        expect(response.status).to eq(200)
      end
    end

    context "when timezone is invalid" do
      let(:env) { {"rack.session" => {"user_id" => 1}, :user_name => "sakuro", :display_name => "Sakuro", :timezone => "Invalid/Zone"} }

      it "falls back to UTC" do
        response = action.call(env)

        expect(user_profile_repo).to have_received(:update_profile).with(1, display_name: "Sakuro")
        expect(user_preference_repo).to have_received(:update_preferences).with(1, timezone: "UTC")
        expect(response.status).to eq(302)
      end
    end
  end
end
