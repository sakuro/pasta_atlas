# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::API::Users::Show do
  let(:find_by_name) { instance_double(PastaAtlas::Operations::User::FindByName) }
  let(:load_profile) { instance_double(PastaAtlas::Operations::User::Profile::Load) }
  let(:action) { PastaAtlas::Actions::API::Users::Show.new(find_by_name:, load_profile:) }

  let(:user) { double("User", id: 1, name: "sakuro", guest?: false) }

  before do
    allow(load_profile).to receive(:call).with(user_id: 1).and_return(Success({display_name: "Sakuro", avatar_url: nil}))
  end

  context "when the user is found" do
    before { allow(find_by_name).to receive(:call).with(user_name: "sakuro").and_return(Success(user)) }

    it "returns 200 with user data" do
      response = action.call({name: "sakuro"})

      expect(response.status).to eq(200)
      body = JSON.parse(response.body.join, symbolize_names: true)
      expect(body[:user][:name]).to eq("sakuro")
      expect(body[:user][:display_name]).to eq("Sakuro")
      expect(body[:user][:avatar_url]).to be_nil
    end
  end

  context "when the user is the guest account" do
    let(:guest) { double("User", id: 999, name: "guest", guest?: true) }

    before { allow(find_by_name).to receive(:call).with(user_name: "guest").and_return(Success(guest)) }

    it "returns 404" do
      response = action.call({name: "guest"})

      expect(response.status).to eq(404)
    end
  end

  context "when the user does not exist" do
    before { allow(find_by_name).to receive(:call).with(user_name: "nobody").and_return(Failure(:not_found)) }

    it "returns 404" do
      response = action.call({name: "nobody"})

      expect(response.status).to eq(404)
    end
  end
end
