# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::Maps::FindByUlid do
  let(:map_repo) { instance_double(PastaAtlas::Repos::MapRepo) }
  let(:operation) { PastaAtlas::Operations::Maps::FindByUlid.new(map_repo:) }

  describe "#call" do
    context "when the map exists" do
      let(:map) { double("Map") }

      before { allow(map_repo).to receive(:find_by_ulid).with("01JXXXX").and_return(map) }

      it "returns success with the map" do
        result = operation.call(ulid: "01JXXXX")

        expect(result).to be_success
        expect(result.value!).to eq(map)
      end
    end

    context "when no map is found" do
      before { allow(map_repo).to receive(:find_by_ulid).with("01JXXXX").and_return(nil) }

      it "returns failure with :not_found" do
        result = operation.call(ulid: "01JXXXX")

        expect(result).to be_failure
        expect(result.failure).to eq(:not_found)
      end
    end
  end
end
