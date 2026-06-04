# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::API::Users::Profile::Show do
  let(:load_profile) { instance_double(PastaAtlas::Operations::User::Profile::Load) }
  let(:verify_ownership) { instance_double(PastaAtlas::Operations::User::VerifyOwnership) }
  let(:user_resolver) { instance_double(PastaAtlas::Resolvers::UserResolver) }
  let(:action) { PastaAtlas::Actions::API::Users::Profile::Show.new(load_profile:, verify_ownership:, user_resolver:) }

  let(:guest) { double("User", id: 0, name: "guest") }
  let(:user) { double("User", id: 1, name: "sakuro") }

  context "when not logged in" do
    let(:env) { {"rack.session" => {}, :user_name => "sakuro"} }

    before do
      allow(user_resolver).to receive(:call).with(nil).and_return(guest)
      allow(verify_ownership).to receive(:call)
        .with(current_user: guest, user_name: "sakuro")
        .and_return(Failure(:forbidden))
    end

    it "returns 403" do
      response = action.call(env)

      expect(response.status).to eq(403)
    end
  end

  context "when logged in as a different user" do
    let(:other_user) { double("User", id: 2, name: "bob") }
    let(:env) { {"rack.session" => {"user_id" => 2}, :user_name => "sakuro"} }

    before do
      allow(user_resolver).to receive(:call).with(2).and_return(other_user)
      allow(verify_ownership).to receive(:call)
        .with(current_user: other_user, user_name: "sakuro")
        .and_return(Failure(:forbidden))
    end

    it "returns 403" do
      response = action.call(env)

      expect(response.status).to eq(403)
    end
  end

  context "when logged in as the owner" do
    let(:env) { {"rack.session" => {"user_id" => 1}, :user_name => "sakuro"} }

    before do
      allow(user_resolver).to receive(:call).with(1).and_return(user)
      allow(verify_ownership).to receive(:call)
        .with(current_user: user, user_name: "sakuro")
        .and_return(Success(user))
      allow(load_profile).to receive(:call)
        .with(user_id: 1)
        .and_return(Success({display_name: "Sakuro", avatar_url: "https://cdn.example.com/avatar.png"}))
    end

    it "returns 200 with profile JSON" do
      response = action.call(env)

      expect(response.status).to eq(200)
      body = JSON.parse(response.body.join)
      expect(body).to include(
        "user_name" => "sakuro",
        "display_name" => "Sakuro",
        "avatar_url" => "https://cdn.example.com/avatar.png"
      )
    end

    context "when the user has no display name or avatar" do
      before do
        allow(load_profile).to receive(:call)
          .with(user_id: 1)
          .and_return(Success({display_name: nil, avatar_url: nil}))
      end

      it "returns nil values" do
        response = action.call(env)

        body = JSON.parse(response.body.join)
        expect(body).to include("display_name" => nil, "avatar_url" => nil)
      end
    end
  end
end
