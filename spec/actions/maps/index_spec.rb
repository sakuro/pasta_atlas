# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::Maps::Index do
  let(:list_maps) { instance_double(PastaAtlas::Operations::Maps::List) }
  let(:action) { PastaAtlas::Actions::Maps::Index.new(list_maps:) }

  let(:map) { double("Map", user_id: 1, ulid: "01MAP", display_name: "My Map") }
  let(:payload) do
    user_info = PastaAtlas::Values::UserInfo[name: "sakuro", display_name: "Sakuro", avatar_url: nil]
    map_info = PastaAtlas::Values::MapInfo[thumbnail_url: nil, metadata_url: nil, updated_at: nil]
    {maps: [map], user_infos_by_user_id: {1 => user_info}, map_infos_by_ulid: {"01MAP" => map_info}, page: 1, per_page: 20, total: 1}
  end

  before do
    allow(list_maps).to receive(:call).and_return(Success(payload))
  end

  it "returns 200" do
    response = action.call({})

    expect(response.status).to eq(200)
  end

  it "calls the operation with the requested page" do
    action.call({page: "2"})

    expect(list_maps).to have_received(:call).with(page: 2)
  end
end
