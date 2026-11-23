# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::API::Users::Avatar::Destroy do
  let(:verify_ownership) { instance_double(PastaAtlas::Operations::User::VerifyOwnership) }
  let(:destroy_avatar) { instance_double(PastaAtlas::Operations::User::Avatar::Destroy) }
  let(:user_resolver) { instance_double(PastaAtlas::Resolvers::UserResolver) }
  let(:action) { PastaAtlas::Actions::API::Users::Avatar::Destroy.new(verify_ownership:, destroy_avatar:, user_resolver:) }

  let(:user) { double("User", id: 1, name: "wube") }
  let(:env) { {"rack.session" => {"user_id" => 1}, :user_name => "wube"} }

  before { allow(user_resolver).to receive(:call).with(1).and_return(user) }

  context "when the user owns the profile" do
    before do
      allow(verify_ownership).to receive(:call).with(current_user: user, user_name: "wube").and_return(Success(user))
      allow(destroy_avatar).to receive(:call).with(user:).and_return(Success(user))
    end

    it "returns 204" do
      response = action.call(env)

      expect(response.status).to eq(204)
      expect(response).to conform_to_openapi("DELETE /api/v1/users/{user_name}/avatar")
    end
  end

  context "when the user does not own the profile" do
    before do
      allow(verify_ownership).to receive(:call).and_return(Failure(:forbidden))
      allow(destroy_avatar).to receive(:call)
    end

    it "returns 403 without removing the avatar" do
      response = action.call(env)

      expect(response.status).to eq(403)
      expect(response).to conform_to_openapi("DELETE /api/v1/users/{user_name}/avatar")
      expect(destroy_avatar).not_to have_received(:call)
    end
  end
end
