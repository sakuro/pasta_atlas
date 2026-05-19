# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::User::Credentials::FindByProviderAndUid do
  let(:credential_repo) { instance_double(PastaAtlas::Repos::CredentialRepo) }
  let(:operation) { PastaAtlas::Operations::User::Credentials::FindByProviderAndUid.new(credential_repo:) }

  describe "#call" do
    context "when the credential exists" do
      let(:credential) { double("Credential", user_id: 1, provider: "github", uid: "12345") }

      before { allow(credential_repo).to receive(:find_by_provider_and_uid).with("github", "12345").and_return(credential) }

      it "returns success with the credential" do
        result = operation.call(provider: "github", uid: "12345")

        expect(result).to be_success
        expect(result.value!).to eq(credential)
      end
    end

    context "when the credential does not exist" do
      before { allow(credential_repo).to receive(:find_by_provider_and_uid).with("github", "99999").and_return(nil) }

      it "returns failure with :not_found" do
        result = operation.call(provider: "github", uid: "99999")

        expect(result).to be_failure
        expect(result.failure).to eq(:not_found)
      end
    end
  end
end
