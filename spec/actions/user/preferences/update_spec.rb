# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::User::Preferences::Update do
  let(:update_preferences) { instance_double(PastaAtlas::Operations::User::Preferences::Update) }
  let(:action) { PastaAtlas::Actions::User::Preferences::Update.new(update_preferences:) }

  let(:user) { double("User", id: 1, name: "sakuro") }

  context "when not logged in" do
    let(:env) { {"rack.session" => {}, :user_name => "sakuro"} }

    before do
      allow(update_preferences).to receive(:call)
        .with(hash_including(user_id: nil, user_name: "sakuro"))
        .and_return(Failure(:forbidden))
    end

    it "returns 403" do
      response = action.call(env)

      expect(response.status).to eq(403)
    end
  end

  context "when logged in as a different user" do
    let(:env) { {"rack.session" => {"user_id" => 1}, :user_name => "bob"} }

    before do
      allow(update_preferences).to receive(:call)
        .with(hash_including(user_id: 1, user_name: "bob"))
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
      allow(update_preferences).to receive(:call)
        .with(hash_including(user_id: 1, user_name: "sakuro"))
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
