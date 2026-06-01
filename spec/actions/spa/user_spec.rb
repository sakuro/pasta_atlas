# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::Spa::User do
  let(:find_by_name) { instance_double(PastaAtlas::Operations::User::FindByName) }
  let(:action) { PastaAtlas::Actions::Spa::User.new(find_by_name:) }

  context "when the user exists" do
    let(:user) { double("User", guest?: false) }

    before { allow(find_by_name).to receive(:call).with(user_name: "sakuro").and_return(Success(user)) }

    it "returns 200" do
      response = action.call({user_name: "sakuro"})

      expect(response.status).to eq(200)
    end
  end

  context "when the user is the guest account" do
    let(:guest) { double("User", guest?: true) }

    before { allow(find_by_name).to receive(:call).with(user_name: "guest").and_return(Success(guest)) }

    it "returns 403" do
      response = action.call({user_name: "guest"})

      expect(response.status).to eq(403)
    end
  end

  context "when the user does not exist" do
    before { allow(find_by_name).to receive(:call).with(user_name: "nobody").and_return(Failure(:not_found)) }

    it "returns 404" do
      response = action.call({user_name: "nobody"})

      expect(response.status).to eq(404)
    end
  end
end
