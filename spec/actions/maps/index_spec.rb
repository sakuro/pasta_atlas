# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::Maps::Index do
  let(:list_maps) { instance_double(PastaAtlas::Operations::Maps::List) }
  let(:action) { PastaAtlas::Actions::Maps::Index.new(list_maps:) }

  let(:payload) do
    user_info = PastaAtlas::Values::UserInfo[name: "sakuro", display_name: "Sakuro", avatar_url: nil]
    map_info = PastaAtlas::Values::MapInfo[ulid: "01MAP", display_name: "My Map", user_info:, thumbnail_url: nil, metadata_url: nil, updated_at: nil]
    {map_infos: [map_info], page: 1, per_page: 20, total: 1}
  end

  before do
    allow(list_maps).to receive(:call).and_return(Success(payload))
  end

  it "returns 200" do
    response = action.call(locale_env)

    expect(response.status).to eq(200)
  end

  it "calls the operation with the requested page" do
    action.call(locale_env.merge(page: "2"))

    expect(list_maps).to have_received(:call).with(page: 2)
  end
end
