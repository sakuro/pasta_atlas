# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::Maps::Index do
  let(:list_maps) { instance_double(PastaAtlas::Operations::Maps::List) }
  let(:action) { PastaAtlas::Actions::Maps::Index.new(list_maps:) }

  let(:map) { double("Map", user_id: 1, ulid: "01MAP", display_name: "My Map") }
  let(:user_profile) { double("UserProfile", user_id: 1, name: "sakuro") }
  let(:payload) do
    {maps: [map], user_profiles_by_id: {1 => user_profile}, page: 1, per_page: 20, total: 1}
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
