# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::Profile::Show do
  let(:user_repo) { instance_double(PastaAtlas::Repos::UserRepo) }
  let(:user_profile_repo) { instance_double(PastaAtlas::Repos::UserProfileRepo) }
  let(:action) { PastaAtlas::Actions::Profile::Show.new(user_repo:, user_profile_repo:) }

  let(:user) { double("User", id: 1, name: "sakuro") }
  let(:profile) { double("UserProfile", display_name: "Sakuro") }

  before do
    allow(user_repo).to receive(:find_by_name).with("sakuro").and_return(user)
    allow(user_profile_repo).to receive(:find_by_user_id).with(1).and_return(profile)
  end

  context "when the user exists" do
    let(:env) { {"rack.session" => {}, :user_name => "sakuro"} }

    it "returns 200" do
      response = action.call(env)

      expect(response.status).to eq(200)
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
