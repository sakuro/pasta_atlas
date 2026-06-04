# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::API::Users::Credentials::Index do
  let(:load_credentials) { instance_double(PastaAtlas::Operations::User::Credentials::Load) }
  let(:verify_ownership) { instance_double(PastaAtlas::Operations::User::VerifyOwnership) }
  let(:user_resolver) { instance_double(PastaAtlas::Providers::UserResolver) }
  let(:action) { PastaAtlas::Actions::API::Users::Credentials::Index.new(load_credentials:, verify_ownership:, user_resolver:) }

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
      allow(load_credentials).to receive(:call)
        .with(user_id: 1)
        .and_return(Success(["github"]))
    end

    it "returns 200 with providers and connected providers JSON" do
      response = action.call(env)

      expect(response.status).to eq(200)
      body = JSON.parse(response.body.join)
      expect(body["providers"]).to eq(%w[discord github steam])
      expect(body["connected_providers"]).to eq(["github"])
    end

    context "when no providers are connected" do
      before do
        allow(load_credentials).to receive(:call)
          .with(user_id: 1)
          .and_return(Success([]))
      end

      it "returns an empty connected_providers array" do
        response = action.call(env)

        body = JSON.parse(response.body.join)
        expect(body["connected_providers"]).to eq([])
      end
    end
  end
end
