# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::Auth::Steam::Callback do
  let(:find_by_id) { instance_double(PastaAtlas::Operations::User::FindById) }
  let(:find_credential) { instance_double(PastaAtlas::Operations::User::Credentials::FindByProviderAndUid) }
  let(:link) { instance_double(PastaAtlas::Operations::User::Credentials::Link) }
  let(:action) { PastaAtlas::Actions::Auth::Steam::Callback.new(find_by_id:, find_credential:, link:) }

  let(:omniauth_auth) { {"provider" => "steam", "uid" => "76561198000000000", "info" => {"nickname" => "steamuser", "image" => ""}} }
  let(:credential) { double("Credential", user_id: 1) }

  context "when steam_pending flag is set in session" do
    let(:env) { {"omniauth.auth" => omniauth_auth, "rack.session" => {steam_pending: true}} }

    before do
      allow(find_credential).to receive(:call).with(provider: "steam", uid: "76561198000000000").and_return(Success(credential))
    end

    it "logs in and clears the steam_pending flag" do
      response = action.call(env)

      expect(response.status).to eq(302)
      expect(env["rack.session"][:steam_pending]).to be_nil
    end
  end

  context "when steam_pending flag is absent" do
    let(:env) { {"omniauth.auth" => omniauth_auth, "rack.session" => {}} }

    it "returns 400" do
      response = action.call(env)

      expect(response.status).to eq(400)
    end
  end
end
