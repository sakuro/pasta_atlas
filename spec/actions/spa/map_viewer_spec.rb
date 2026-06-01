# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::Spa::MapViewer do
  let(:find_map) { instance_double(PastaAtlas::Operations::Maps::FindByUlid) }
  let(:action) { PastaAtlas::Actions::Spa::MapViewer.new(find_map:) }

  let(:ulid) { "01JXXXXXXXXXXXXXXXXXXXX" }

  context "when the map exists" do
    before { allow(find_map).to receive(:call).with(ulid:).and_return(Success(double("Map"))) }

    it "returns 200" do
      response = action.call({map_ulid: ulid})

      expect(response.status).to eq(200)
    end
  end

  context "when the map is not found" do
    before { allow(find_map).to receive(:call).with(ulid:).and_return(Failure(:not_found)) }

    it "returns 404" do
      response = action.call({map_ulid: ulid})

      expect(response.status).to eq(404)
    end
  end
end
