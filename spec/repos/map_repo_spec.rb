# frozen_string_literal: true

RSpec.describe PastaAtlas::Repos::MapRepo, :db do
  let(:repo) { Hanami.app["repos.map_repo"] }
  let!(:map) { Factory[:map] }

  describe "#update_display_name" do
    it "sets the display name" do
      repo.update_display_name(id: map.id, display_name: "My map")

      expect(repo.find_by_id!(map.id).display_name).to eq("My map")
    end
  end

  describe "#delete_by_id" do
    it "deletes the map" do
      repo.delete_by_id(map.id)

      expect(repo.find_by_ulid(map.ulid)).to be_nil
    end
  end

  describe "#find_by_id!" do
    it "raises for an unknown id" do
      expect { repo.find_by_id!(0) }.to raise_error(ROM::TupleCountMismatchError)
    end
  end
end
