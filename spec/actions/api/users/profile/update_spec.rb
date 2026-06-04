# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::API::Users::Profile::Update do
  let(:update_profile) { instance_double(PastaAtlas::Operations::User::Profile::Update) }
  let(:load_profile) { instance_double(PastaAtlas::Operations::User::Profile::Load) }
  let(:action) { PastaAtlas::Actions::API::Users::Profile::Update.new(load_profile:, update_profile:) }

  let(:user) { double("User", id: 1, name: "sakuro") }

  before do
    allow(load_profile).to receive(:call).with(user_id: 1)
      .and_return(Success({display_name: "Sakuro", avatar_url: nil}))
  end

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

    it "returns 200 with updated profile data" do
      response = action.call(env)

      expect(response.status).to eq(200)
      body = JSON.parse(response.body.join)
      expect(body["display_name"]).to eq("Sakuro")
      expect(body["avatar_url"]).to be_nil
    end

    context "when display_name is invalid" do
      let(:env) { {"rack.session" => {"user_id" => 1}, :user_name => "sakuro", :display_name => "あ" * 65} }

      before do
        allow(update_profile).to receive(:call)
          .with(hash_including(user_id: 1, user_name: "sakuro"))
          .and_return(Failure([:invalid, "error-profile-display-name-too-long"]))
      end

      it "returns 422 with error" do
        response = action.call(env)

        expect(response.status).to eq(422)
        body = JSON.parse(response.body.join)
        expect(body["error"]).to eq("error-profile-display-name-too-long")
      end
    end
  end
end
