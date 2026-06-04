# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::API::Users::Preferences::Update do
  let(:verify_ownership) { instance_double(PastaAtlas::Operations::User::VerifyOwnership) }
  let(:update_preferences) { instance_double(PastaAtlas::Operations::User::Preferences::Update) }
  let(:user_resolver) { instance_double(PastaAtlas::Providers::UserResolver) }
  let(:action) { PastaAtlas::Actions::API::Users::Preferences::Update.new(verify_ownership:, update_preferences:, user_resolver:) }

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
    let(:other_user) { double("User", id: 1, name: "bob") }
    let(:env) { {"rack.session" => {"user_id" => 1}, :user_name => "sakuro"} }

    before do
      allow(user_resolver).to receive(:call).with(1).and_return(other_user)
      allow(verify_ownership).to receive(:call)
        .with(current_user: other_user, user_name: "sakuro")
        .and_return(Failure(:forbidden))
    end

    it "returns 403" do
      response = action.call(env)

      expect(response.status).to eq(403)
    end
  end

  context "when logged in" do
    let(:env) { {"rack.session" => {"user_id" => 1}, :user_name => "sakuro", :timezone => "Asia/Tokyo", :locale => "ja"} }

    before do
      allow(user_resolver).to receive(:call).with(1).and_return(user)
      allow(verify_ownership).to receive(:call)
        .with(current_user: user, user_name: "sakuro")
        .and_return(Success(user))
      allow(update_preferences).to receive(:call)
        .with(hash_including(user:))
        .and_return(Success({user:, locale: "ja"}))
    end

    it "returns 200 with locale" do
      response = action.call(env)

      expect(response.status).to eq(200)
      body = JSON.parse(response.body.join)
      expect(body["locale"]).to eq("ja")
    end

    it "keeps locale in session" do
      action.call(env)

      expect(env["rack.session"]["locale"]).to eq("ja")
    end
  end
end
