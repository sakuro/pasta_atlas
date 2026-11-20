# frozen_string_literal: true

RSpec.describe PastaAtlas::Repos::GenerationRepo, :db do
  let(:repo) { Hanami.app["repos.generation_repo"] }
  let!(:generation) { Factory[:generation] }

  describe "#update_storage_bytes" do
    it "stores the size" do
      repo.update_storage_bytes(id: generation.id, storage_bytes: 12_345)

      expect(repo.fetch_by_id(generation.id).storage_bytes).to eq(12_345)
    end
  end

  describe "#delete_by_id" do
    it "deletes the generation" do
      repo.delete_by_id(generation.id)

      expect { repo.fetch_by_id(generation.id) }.to raise_error(ROM::TupleCountMismatchError)
    end
  end
end
