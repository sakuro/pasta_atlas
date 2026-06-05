# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::Auth::Registrations::Create do
  let(:create_registration) { instance_double(PastaAtlas::Operations::Registrations::Create) }
  let(:action) { PastaAtlas::Actions::Auth::Registrations::Create.new(create_registration:) }

  let(:pending_auth) { {"provider" => "github", "uid" => "12345", "avatar_url" => ""} }
  let(:base_env) { {"rack.session" => {"pending_auth" => pending_auth}, :name => "alice", :terms => "1"} }

  context "when pending_auth is missing from session" do
    let(:env) { {"rack.session" => {}} }

    it "returns 403" do
      response = action.call(env)

      expect(response.status).to eq(403)
    end
  end

  context "when terms are not agreed" do
    let(:env) { {"rack.session" => {"pending_auth" => pending_auth}, :name => "alice"} }

    it "returns 422 with error" do
      response = action.call(env)

      expect(response.status).to eq(422)
      body = JSON.parse(response.body.join)
      expect(body["error"]).to eq("error-terms-required")
    end
  end

  context "when registration fails with validation error" do
    before do
      allow(create_registration).to receive(:call).and_return(Failure([:invalid, "error-username-taken"]))
    end

    it "returns 422 with error" do
      response = action.call(base_env)

      expect(response.status).to eq(422)
      body = JSON.parse(response.body.join)
      expect(body["error"]).to eq("error-username-taken")
    end
  end

  context "when registration succeeds" do
    let(:user) { double("User", id: 1) }

    before do
      allow(create_registration).to receive(:call).and_return(Success(user))
    end

    it "returns 200 with redirect_to" do
      response = action.call(base_env)

      expect(response.status).to eq(200)
      body = JSON.parse(response.body.join)
      expect(body["redirect_to"]).to eq("/")
    end
  end
end
