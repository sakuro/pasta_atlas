# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::Auth::Registrations::Create, :action_env do
  let(:create_registration) { instance_double(PastaAtlas::Operations::Registrations::Create) }
  let(:action) { PastaAtlas::Actions::Auth::Registrations::Create.new(create_registration:) }

  let(:pending_auth) { {"provider" => "github", "uid" => "12345", "avatar_url" => ""} }
  let(:base_env) { locale_env.merge("rack.session" => {"pending_auth" => pending_auth}, :name => "alice") }

  context "when pending_auth is missing from session" do
    let(:env) { locale_env.merge("rack.session" => {}) }

    it "returns 403" do
      response = action.call(env)

      expect(response.status).to eq(403)
    end
  end

  context "when registration fails with validation error" do
    before do
      allow(create_registration).to receive(:call).and_return(Failure([:invalid, "error-username-taken"]))
    end

    it "renders the form with an error" do
      response = action.call(base_env)

      expect(response.status).to eq(200)
    end
  end

  context "when registration succeeds" do
    let(:user) { double("User", id: 1) }

    before do
      allow(create_registration).to receive(:call).and_return(Success(user))
    end

    it "redirects to root" do
      response = action.call(base_env)

      expect(response.status).to eq(302)
      expect(response.headers["Location"]).to eq("/")
    end
  end
end
