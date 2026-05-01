# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::Profile::Update do
  let(:user_repo) { instance_double(PastaAtlas::Repos::UserRepo) }
  let(:user_profile_repo) { instance_double(PastaAtlas::Repos::UserProfileRepo) }
  let(:action) { PastaAtlas::Actions::Profile::Update.new(user_repo:, user_profile_repo:, edit_view:) }
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
    let(:env) { {"rack.session" => {"user_id" => 1}, :user_name => "sakuro", :display_name => "Sakuro"} }

    before do
      allow(user_profile_repo).to receive(:update_display_name)
    end

    it "updates the display name and redirects" do
      response = action.call(env)

      expect(user_profile_repo).to have_received(:update_display_name).with(1, "Sakuro")
      expect(response.status).to eq(302)
    end

    context "when display_name is blank" do
      let(:env) { {"rack.session" => {"user_id" => 1}, :user_name => "sakuro", :display_name => ""} }

      it "clears display name" do
        response = action.call(env)

        expect(user_profile_repo).to have_received(:update_display_name).with(1, nil)
        expect(response.status).to eq(302)
      end
    end

    context "when display_name exceeds 64 grapheme clusters" do
      let(:env) { {"rack.session" => {"user_id" => 1}, :user_name => "sakuro", :display_name => "あ" * 65} }

      it "re-renders the form without updating" do
        response = action.call(env)

        expect(user_profile_repo).not_to have_received(:update_display_name)
        expect(response.status).to eq(200)
      end
    end
  end
end
