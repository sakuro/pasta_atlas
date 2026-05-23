# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::Maps::FindByMapshotId do
  let(:map_repo) { instance_double(PastaAtlas::Repos::MapRepo) }
  let(:operation) { PastaAtlas::Operations::Maps::FindByMapshotId.new(map_repo:) }

  describe "#call" do
    context "when a map is found" do
      let(:map) { double("Map", id: 1, name: "My Custom Map") }

      before do
        allow(map_repo).to receive(:find_by_user_and_mapshot_id)
          .with(user_id: 1, mapshot_map_id: "ae8ec3ab")
          .and_return(map)
      end

      it "returns success with the map" do
        result = operation.call(user_id: 1, mapshot_map_id: "ae8ec3ab")

        expect(result).to be_success
        expect(result.value!).to eq(map)
      end
    end

    context "when no map is found" do
      before do
        allow(map_repo).to receive(:find_by_user_and_mapshot_id)
          .with(user_id: 1, mapshot_map_id: "ae8ec3ab")
          .and_return(nil)
      end

      it "returns failure with :not_found" do
        result = operation.call(user_id: 1, mapshot_map_id: "ae8ec3ab")

        expect(result).to be_failure
        expect(result.failure).to eq(:not_found)
      end
    end
  end
end
