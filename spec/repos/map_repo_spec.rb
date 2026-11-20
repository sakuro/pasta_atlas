# frozen_string_literal: true

RSpec.describe PastaAtlas::Repos::MapRepo, :db do
  let(:repo) { Hanami.app["repos.map_repo"] }
  let!(:map) { Factory[:map] }

  describe "#update_name" do
    it "sets the name" do
      repo.update_name(id: map.id, name: "My map")

      expect(repo.fetch_by_id(map.id).name).to eq("My map")
    end

    it "clears the name when it is empty" do
      repo.update_name(id: map.id, name: "My map")
      repo.update_name(id: map.id, name: "")

      expect(repo.fetch_by_id(map.id).name).to be_nil
    end
  end

  describe "#delete_by_id" do
    it "deletes the map" do
      repo.delete_by_id(map.id)

      expect(repo.find_by_ulid(map.ulid)).to be_nil
    end
  end

  describe "#fetch_by_id" do
    it "raises for an unknown id" do
      expect { repo.fetch_by_id(0) }.to raise_error(ROM::TupleCountMismatchError)
    end
  end
end
