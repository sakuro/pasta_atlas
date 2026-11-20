# frozen_string_literal: true

RSpec.describe PastaAtlas::Repos::UserRepo, :db do
  let(:repo) { Hanami.app["repos.user_repo"] }

  describe "#find_by_id" do
    it "returns the user" do
      user = Factory[:user]

      expect(repo.find_by_id(user.id).name).to eq(user.name)
    end

    it "returns nil for an unknown id" do
      expect(repo.find_by_id(0)).to be_nil
    end
  end

  describe "#find_by_id!" do
    it "raises for an unknown id" do
      expect { repo.find_by_id!(0) }.to raise_error(ROM::TupleCountMismatchError)
    end
  end

  describe "#find_or_create_by_name" do
    it "creates the user once and returns the existing one afterwards" do
      first = repo.find_or_create_by_name(name: "newcomer")
      second = repo.find_or_create_by_name(name: "newcomer")

      expect(second.id).to eq(first.id)
    end
  end

  describe "#destroy" do
    it "deletes the user" do
      user = Factory[:user]

      repo.destroy(user.id)

      expect(repo.find_by_id(user.id)).to be_nil
    end
  end
end
