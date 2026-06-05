# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::API::Auth::Registration do
  let(:action) { PastaAtlas::Actions::API::Auth::Registration.new }

  context "when no pending_auth in session" do
    it "returns 401" do
      response = action.call({})

      expect(response.status).to eq(401)
    end
  end

  context "when pending_auth is in session" do
    let(:pending_auth) { {"provider" => "github", "uid" => "12345", "login" => "alice", "avatar_url" => ""} }
    let(:env) { {"rack.session" => {"pending_auth" => pending_auth}} }

    it "returns 200 with provider and login_name" do
      response = action.call(env)

      expect(response.status).to eq(200)
      body = JSON.parse(response.body.join)
      expect(body["provider"]).to eq("github")
      expect(body["login_name"]).to eq("alice")
    end
  end
end
