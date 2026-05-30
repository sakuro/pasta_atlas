# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::User::Profile::Update do
  let(:update_profile) { instance_double(PastaAtlas::Operations::User::Profile::Update) }
  let(:action) { PastaAtlas::Actions::User::Profile::Update.new(update_profile:) }

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
      expect(response.headers["Location"]).to eq("/@sakuro#tab-profile")
    end

    context "when display_name is invalid" do
      let(:env) { {"rack.session" => {"user_id" => 1}, :user_name => "sakuro", :display_name => "あ" * 65} }

      before do
        allow(update_profile).to receive(:call)
          .with(hash_including(user_id: 1, user_name: "sakuro"))
          .and_return(Failure([:invalid, "Display name must be 64 characters or fewer."]))
      end

      it "redirects back to the profile tab with a flash error" do
        response = action.call(env)

        expect(response.status).to eq(302)
        expect(response.headers["Location"]).to eq("/@sakuro#tab-profile")
      end
    end
  end
end
