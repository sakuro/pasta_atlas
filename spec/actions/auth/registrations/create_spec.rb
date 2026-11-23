# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::Auth::Registrations::Create do
  let(:create_registration) { instance_double(PastaAtlas::Operations::Registrations::Create) }
  let(:action) { PastaAtlas::Actions::Auth::Registrations::Create.new(create_registration:) }

  let(:pending_auth) { {"provider" => "github", "uid" => "12345", "login" => "alice", "avatar_url" => ""} }
  let(:base_env) { {"rack.session" => {"pending_auth" => pending_auth}, :name => "alice", :terms => true} }

  context "when pending_auth is missing from session" do
    let(:env) { {"rack.session" => {}, :name => "alice", :terms => true} }

    it "returns 403" do
      response = action.call(env)

      expect(response.status).to eq(403)
      expect(response).to conform_to_openapi("POST /auth/register")
    end
  end

  context "when terms are not accepted" do
    let(:env) { base_env.merge(terms: false) }

    it "returns 422 with error" do
      response = action.call(env)

      expect(response.status).to eq(422)
      expect(response).to conform_to_openapi("POST /auth/register")
      body = JSON.parse(response.body.join)
      expect(body["error"]).to eq("error-terms-required")
    end
  end

  context "when terms are missing" do
    let(:env) { base_env.except(:terms) }

    before { allow(create_registration).to receive(:call) }

    it "returns 400 without calling the operation" do
      response = action.call(env)

      expect(response.status).to eq(400)
      expect(response).to conform_to_openapi("POST /auth/register")
      expect(create_registration).not_to have_received(:call)
    end
  end

  context "when terms are not a boolean" do
    let(:env) { base_env.merge(terms: "1") }

    before { allow(create_registration).to receive(:call) }

    it "returns 400 without calling the operation" do
      response = action.call(env)

      expect(response.status).to eq(400)
      expect(response).to conform_to_openapi("POST /auth/register")
      expect(create_registration).not_to have_received(:call)
    end
  end

  context "when the name is missing" do
    let(:env) { base_env.except(:name) }

    before { allow(create_registration).to receive(:call) }

    it "returns 400 without calling the operation" do
      response = action.call(env)

      expect(response.status).to eq(400)
      expect(response).to conform_to_openapi("POST /auth/register")
      expect(create_registration).not_to have_received(:call)
    end
  end

  context "when the name is empty" do
    let(:env) { base_env.merge(name: "") }

    before do
      allow(create_registration).to receive(:call)
        .with(hash_including(name: ""))
        .and_return(Failure([:invalid, "error-username-empty"]))
    end

    it "returns 422 with the error of the operation" do
      response = action.call(env)

      expect(response.status).to eq(422)
      expect(response).to conform_to_openapi("POST /auth/register")
      body = JSON.parse(response.body.join)
      expect(body["error"]).to eq("error-username-empty")
    end
  end

  context "when registration fails with validation error" do
    before do
      allow(create_registration).to receive(:call).and_return(Failure([:invalid, "error-username-taken"]))
    end

    it "returns 422 with error" do
      response = action.call(base_env)

      expect(response.status).to eq(422)
      expect(response).to conform_to_openapi("POST /auth/register")
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
      expect(response).to conform_to_openapi("POST /auth/register")
      body = JSON.parse(response.body.join)
      expect(body["redirect_to"]).to eq("/")
    end

    it "passes the lowercased name and the pending identity to the operation" do
      action.call(base_env.merge(name: "Alice"))

      expect(create_registration).to have_received(:call)
        .with(name: "alice", timezone: "", provider: "github", uid: "12345", avatar_url: "")
    end
  end
end
