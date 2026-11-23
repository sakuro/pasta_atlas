# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::API::Users::Credentials::Destroy do
  let(:verify_ownership) { instance_double(PastaAtlas::Operations::User::VerifyOwnership) }
  let(:unlink) { instance_double(PastaAtlas::Operations::User::Credentials::Unlink) }
  let(:user_resolver) { instance_double(PastaAtlas::Resolvers::UserResolver) }
  let(:action) { PastaAtlas::Actions::API::Users::Credentials::Destroy.new(verify_ownership:, unlink:, user_resolver:) }

  let(:user) { double("User", id: 1, name: "wube") }
  let(:env) { {"rack.session" => {"user_id" => 1}, :user_name => "wube", :provider => "github"} }
  let(:operation) { "DELETE /api/v1/users/{user_name}/credentials/{provider}" }

  before { allow(user_resolver).to receive(:call).with(1).and_return(user) }

  context "when the user owns the credentials" do
    before { allow(verify_ownership).to receive(:call).with(current_user: user, user_name: "wube").and_return(Success(user)) }

    it "returns 204 after unlinking the provider" do
      allow(unlink).to receive(:call).with(user_id: 1, provider: "github").and_return(Success())

      response = action.call(env)

      expect(response.status).to eq(204)
      expect(response).to conform_to_openapi(operation)
    end

    it "returns 422 for the last credential" do
      allow(unlink).to receive(:call).with(user_id: 1, provider: "github").and_return(Failure(:last_credential))

      response = action.call(env)

      expect(response.status).to eq(422)
      expect(JSON.parse(response.body.join)).to eq("error" => "error-credential-last")
      expect(response).to conform_to_openapi(operation)
    end

    it "returns 404 for an unknown provider" do
      allow(unlink).to receive(:call)

      response = action.call(env.merge(provider: "gitlab"))

      expect(response.status).to eq(404)
      expect(response).to conform_to_openapi(operation)
      expect(unlink).not_to have_received(:call)
    end
  end

  context "when the user does not own the credentials" do
    before do
      allow(verify_ownership).to receive(:call).and_return(Failure(:forbidden))
      allow(unlink).to receive(:call)
    end

    it "returns 403 without unlinking" do
      response = action.call(env)

      expect(response.status).to eq(403)
      expect(response).to conform_to_openapi(operation)
      expect(unlink).not_to have_received(:call)
    end
  end
end
