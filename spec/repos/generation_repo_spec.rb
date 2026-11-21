# frozen_string_literal: true

RSpec.describe PastaAtlas::Repos::GenerationRepo, :db do
  let(:repo) { Hanami.app["repos.generation_repo"] }
  let!(:generation) { Factory[:generation] }

  describe "#create" do
    it "stores the generation and returns it" do
      map = Factory[:map]

      created = repo.create(ulid: ULID.generate, map_id: map.id, mapshot_unique_id: "created-gen", tick: 2000, metadata_s3_key: "created-gen/mapshot.json")

      expect(repo.find_by_id!(created.id)).to have_attributes(
        map_id: map.id, mapshot_unique_id: "created-gen", tick: 2000, metadata_s3_key: "created-gen/mapshot.json", storage_bytes: nil
      )
    end
  end

  describe "#update_storage_bytes" do
    it "stores the size" do
      repo.update_storage_bytes(id: generation.id, storage_bytes: 12_345)

      expect(repo.find_by_id!(generation.id).storage_bytes).to eq(12_345)
    end
  end

  describe "#delete_by_id" do
    it "deletes the generation" do
      repo.delete_by_id(generation.id)

      expect { repo.find_by_id!(generation.id) }.to raise_error(ROM::TupleCountMismatchError)
    end
  end
end
