# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::Auth::OAuthCallback do
  let(:find_by_id) { instance_double(PastaAtlas::Operations::User::FindById) }
  let(:find_credential) { instance_double(PastaAtlas::Operations::User::Credentials::FindByProviderAndUid) }
  let(:link) { instance_double(PastaAtlas::Operations::User::Credentials::Link) }
  let(:action) { PastaAtlas::Actions::Auth::OAuthCallback.new(find_by_id:, find_credential:, link:) }

  let(:omniauth_auth) { {"provider" => "github", "uid" => "12345", "info" => {"nickname" => "alice", "image" => "http://example.com/avatar.jpg"}} }
  let(:base_env) { {"omniauth.auth" => omniauth_auth} }

  context "when omniauth.auth is missing" do
    let(:env) { {"rack.session" => {}} }

    it "returns 400" do
      response = action.call(env)

      expect(response.status).to eq(400)
    end
  end

  context "when no existing credential and not logged in" do
    let(:env) { base_env.merge("rack.session" => {}) }

    before { allow(find_credential).to receive(:call).with(provider: "github", uid: "12345").and_return(Failure(:not_found)) }

    it "stores pending_auth in session and redirects to register" do
      response = action.call(env)

      expect(response.status).to eq(302)
      expect(response.headers["Location"]).to eq("/auth/register")
    end
  end

  context "when credential exists and not logged in" do
    let(:credential) { double("Credential", user_id: 1) }
    let(:env) { base_env.merge("rack.session" => {}) }

    before do
      allow(find_credential).to receive(:call).with(provider: "github", uid: "12345").and_return(Success(credential))
    end

    it "logs in and redirects to root" do
      response = action.call(env)

      expect(response.status).to eq(302)
      expect(response.headers["Location"]).to eq("/")
    end
  end

  context "when logged in and connecting a new provider" do
    let(:user) { double("User", name: "alice") }
    let(:env) { base_env.merge("rack.session" => {"user_id" => 1}) }

    before do
      allow(find_credential).to receive(:call).with(provider: "github", uid: "12345").and_return(Failure(:not_found))
      allow(find_by_id).to receive(:call).with(user_id: 1).and_return(Success(user))
      allow(link).to receive(:call).with(user_id: 1, provider: "github", uid: "12345").and_return(Success(nil))
    end

    it "links the provider and redirects to user page" do
      response = action.call(env)

      expect(response.status).to eq(302)
      expect(response.headers["Location"]).to eq("/@alice#tab-credentials")
    end
  end
end
