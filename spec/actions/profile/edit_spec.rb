# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::Profile::Edit do
  let(:user_repo) { instance_double(PastaAtlas::Repos::UserRepo) }
  let(:user_profile_repo) { instance_double(PastaAtlas::Repos::UserProfileRepo) }
  let(:action) { PastaAtlas::Actions::Profile::Edit.new(user_repo:, user_profile_repo:) }

  let(:user) { double("User", id: 1, name: "sakuro") }
  let(:profile) { double("UserProfile", display_name: "Sakuro") }

  before do
    allow(user_repo).to receive(:find_by_id).with(1).and_return(user)
    allow(user_profile_repo).to receive(:find_by_user_id).with(1).and_return(profile)
  end

  context "when logged in as the profile owner" do
    let(:env) { {"rack.session" => {"user_id" => 1}, :user_name => "sakuro"} }

    it "returns 200" do
      response = action.call(env)

      expect(response.status).to eq(200)
    end
  end

  context "when not logged in" do
    let(:env) { {"rack.session" => {}, :user_name => "sakuro"} }

    it "returns 403" do
      response = action.call(env)

      expect(response.status).to eq(403)
    end
  end

  context "when logged in as a different user" do
    let(:env) { {"rack.session" => {"user_id" => 1}, :user_name => "bob"} }

    it "returns 403" do
      response = action.call(env)

      expect(response.status).to eq(403)
    end
  end
end
