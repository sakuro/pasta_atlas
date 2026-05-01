# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::Maps::Index do
  let(:list_maps) { instance_double(PastaAtlas::Operations::Maps::List) }
  let(:action) { PastaAtlas::Actions::Maps::Index.new(list_maps:) }

  let(:map) { double("Map", user_id: 1, ulid: "01MAP", display_name: "My Map") }
  let(:user) { double("User", id: 1, name: "sakuro") }
  let(:profile) { double("UserProfile", display_name: "Sakuro") }
  let(:payload) do
    {maps: [map], users_by_id: {1 => user}, profiles_by_user_id: {1 => profile}, thumbnail_urls_by_map_ulid: {}, page: 1, per_page: 20, total: 1}
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
