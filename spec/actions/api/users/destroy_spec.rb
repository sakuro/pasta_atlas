# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::API::Users::Destroy do
  let(:verify_ownership) { instance_double(PastaAtlas::Operations::User::VerifyOwnership) }
  let(:destroy_user) { instance_double(PastaAtlas::Operations::User::Destroy) }
  let(:user_resolver) { instance_double(PastaAtlas::Resolvers::UserResolver) }
  let(:action) { PastaAtlas::Actions::API::Users::Destroy.new(verify_ownership:, destroy_user:, user_resolver:) }

  let(:user) { double("User", id: 1, name: "wube") }
  let(:session) { {"user_id" => 1} }
  let(:env) { {"rack.session" => session, :user_name => "wube", :confirm_user_name => "wube"} }

  before do
    allow(user_resolver).to receive(:call).with(1).and_return(user)
    allow(verify_ownership).to receive(:call).with(current_user: user, user_name: "wube").and_return(Success(user))
  end

  context "when the account is deleted" do
    before { allow(destroy_user).to receive(:call).with(user:).and_return(Success(user)) }

    it "returns the redirect target and clears the session" do
      response = action.call(env)

      expect(response.status).to eq(200)
      expect(response).to conform_to_openapi("DELETE /api/v1/users/{user_name}")
      expect(JSON.parse(response.body.join)).to eq("redirect_to" => "/")
      expect(session).to be_empty
    end
  end

  context "when a cleanup message cannot be queued" do
    before { allow(destroy_user).to receive(:call).with(user:).and_return(Failure(:bad_gateway)) }

    it "returns 502 and keeps the session, so that the user can try again" do
      response = action.call(env)

      expect(response.status).to eq(502)
      expect(response).to conform_to_openapi("DELETE /api/v1/users/{user_name}")
      expect(session).to eq({"user_id" => 1})
    end
  end

  context "when the confirmation does not match" do
    it "returns 400 without deleting anything" do
      allow(destroy_user).to receive(:call)

      response = action.call(env.merge(confirm_user_name: "other"))

      expect(response.status).to eq(400)
      expect(response).to conform_to_openapi("DELETE /api/v1/users/{user_name}")
      expect(destroy_user).not_to have_received(:call)
    end
  end
end
