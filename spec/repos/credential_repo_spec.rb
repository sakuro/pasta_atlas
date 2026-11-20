# frozen_string_literal: true

RSpec.describe PastaAtlas::Repos::CredentialRepo, :db do
  let(:repo) { Hanami.app["repos.credential_repo"] }
  let(:user) { Factory[:user] }

  describe "#delete_by_user_id_and_provider" do
    it "deletes only the credential of that provider" do
      repo.create(user_id: user.id, provider: "github", uid: "1")
      repo.create(user_id: user.id, provider: "discord", uid: "2")

      repo.delete_by_user_id_and_provider(user.id, "github")

      expect(repo.find_by_user_id(user.id).map(&:provider)).to eq(["discord"])
    end
  end
end
