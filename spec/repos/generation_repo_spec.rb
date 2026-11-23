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

  describe "#find_last_completed_at_by_map_ids" do
    def generation_with_status(map, event_type, occurred_at, created_at: occurred_at)
      gen = Factory[:generation, map:, created_at:]
      upload = Factory[:upload, generation: gen]
      Factory[:upload_event, upload:, event_type:, occurred_at:]
      gen
    end

    let(:map) { Factory[:map] }
    let(:old_time) { Time.at(Time.now.to_i - 7200) }
    let(:new_time) { Time.at(Time.now.to_i - 3600) }

    it "returns an empty hash for no map ids" do
      expect(repo.find_last_completed_at_by_map_ids([])).to eq({})
    end

    it "ignores pending and failed uploads newer than the complete one" do
      generation_with_status(map, "complete", old_time)
      generation_with_status(map, "pending", new_time)
      generation_with_status(map, "failed", new_time)

      expect(repo.find_last_completed_at_by_map_ids([map.id])).to eq({map.id => old_time})
    end

    it "uses the latest completion" do
      generation_with_status(map, "complete", old_time)
      generation_with_status(map, "complete", new_time)

      expect(repo.find_last_completed_at_by_map_ids([map.id])).to eq({map.id => new_time})
    end

    it "uses when an upload completed, not when it started" do
      generation_with_status(map, "complete", new_time, created_at: old_time - 3600)
      generation_with_status(map, "complete", old_time, created_at: old_time)

      expect(repo.find_last_completed_at_by_map_ids([map.id])).to eq({map.id => new_time})
    end

    it "omits maps without a complete generation" do
      generation_with_status(map, "pending", new_time)

      expect(repo.find_last_completed_at_by_map_ids([map.id])).to eq({})
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
